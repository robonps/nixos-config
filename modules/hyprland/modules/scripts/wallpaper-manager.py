#!/usr/bin/env python3
"""Wallpaper library and session-owned awww/mpvpaper controller."""

import argparse
import ctypes
import fcntl
import hashlib
import json
import math
import os
from pathlib import Path
import random
import signal
import socket
import subprocess
import sys
import time
import uuid


IMAGES = {".jpg", ".jpeg", ".png", ".webp", ".gif"}
VIDEOS = {".mp4", ".webm", ".mkv", ".mov", ".m4v"}
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "wallpaper-picker"
CONFIG = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
SESSION = hashlib.sha256(os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "default").encode()).hexdigest()[:12]
RUNTIME = Path(os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")) / f"wallpaper-{SESSION}"


def run(*args):
    return subprocess.run(args, check=True, capture_output=True, text=True, timeout=120).stdout


def read_json(path, default):
    try:
        return json.loads(path.read_text())
    except (OSError, ValueError):
        return default


def save_state(state):
    CACHE.mkdir(parents=True, exist_ok=True)
    temporary = CACHE / "state.tmp"
    temporary.write_text(json.dumps(state))
    temporary.replace(CACHE / "state.json")
    (CACHE / "current").write_text(state.get("current", "") + "\n")


def media_key(path):
    stat = path.stat()
    return hashlib.sha256(f"{path}\0{stat.st_size}\0{stat.st_mtime_ns}".encode()).hexdigest()


def poster(path):
    if path.suffix.lower() not in VIDEOS:
        return path
    directory = CACHE / "frames"
    directory.mkdir(parents=True, exist_ok=True)
    frame = directory / f"{media_key(path)}.jpg"
    if not frame.exists():
        temporary = frame.with_suffix(f".{uuid.uuid4().hex}.jpg")
        try:
            # The thumbnail filter chooses a representative frame from the first 100.
            run("ffmpeg", "-nostdin", "-v", "error", "-i", str(path), "-vf",
                "thumbnail,scale=1280:720:force_original_aspect_ratio=decrease",
                "-frames:v", "1", "-update", "1", "-y", str(temporary))
            if not temporary.exists() or not temporary.stat().st_size:
                raise ValueError(f"No video frame could be extracted from {path.name}")
            temporary.replace(frame)
        finally:
            temporary.unlink(missing_ok=True)
    return frame


def thumbnail_path(path):
    return CACHE / "thumbnails" / f"{media_key(path)}-360-v1.jpg"


def thumbnail(path):
    """Small picker-only preview; theme generation keeps its larger source frame."""
    destination = thumbnail_path(path)
    if destination.is_file():
        return destination
    destination.parent.mkdir(parents=True, exist_ok=True)
    temporary = destination.with_suffix(f".{uuid.uuid4().hex}.jpg")
    try:
        frame = CACHE / "frames" / f"{media_key(path)}.jpg"
        if path.suffix.lower() in VIDEOS and not frame.is_file():
            # Decode just one frame for browsing, rather than the representative
            # 100-frame sample used when applying the video and generating its theme.
            run("ffmpeg", "-nostdin", "-v", "error", "-i", str(path), "-an", "-sn",
                "-vf", "scale=360:360:force_original_aspect_ratio=increase,crop=360:360",
                "-frames:v", "1", "-update", "1", "-y", str(temporary))
        else:
            source = frame if path.suffix.lower() in VIDEOS else path
            run("magick", f"{source}[0]", "-auto-orient", "-thumbnail", "360x360^",
                "-gravity", "center", "-extent", "360x360", "-strip", "-quality", "85", str(temporary))
        if not temporary.is_file() or not temporary.stat().st_size:
            raise ValueError(f"No thumbnail could be generated for {path.name}")
        temporary.replace(destination)
    finally:
        temporary.unlink(missing_ok=True)
    return destination


def monitors():
    result = []
    for monitor in json.loads(run("hyprctl", "monitors", "-j")):
        if monitor.get("disabled"):
            continue
        width, height = monitor["width"], monitor["height"]
        if monitor.get("transform", 0) % 2:
            width, height = height, width
        result.append(dict(monitor, w=round(width / monitor["scale"]),
                           h=round(height / monitor["scale"])))
    return sorted(result, key=lambda m: (m["x"], m["y"], m["name"]))


def bounds(outputs):
    x = min(m["x"] for m in outputs)
    y = min(m["y"] for m in outputs)
    return x, y, max(m["x"] + m["w"] for m in outputs) - x, max(m["y"] + m["h"] for m in outputs) - y


def video_transform(monitor, outputs, width, height, render_size=None):
    """GPU scaling/panning: each output views the same centered virtual canvas."""
    x, y, canvas_w, canvas_h = bounds(outputs)
    factor = max(canvas_w / width, canvas_h / height)
    # mpvpaper renders into integer-scaled Wayland buffers, including on fractional
    # scale monitors. Prefer its actual framebuffer size over the compositor scale.
    scale_x = render_size[0] / monitor["w"] if render_size else math.ceil(monitor["scale"])
    scale_y = render_size[1] / monitor["h"] if render_size else math.ceil(monitor["scale"])
    return {
        "video-unscaled": "yes",
        "video-scale-x": factor * scale_x,
        "video-scale-y": factor * scale_y,
        "video-pan-x": (canvas_w / 2 - (monitor["x"] - x) - monitor["w"] / 2) / (width * factor),
        "video-pan-y": (canvas_h / 2 - (monitor["y"] - y) - monitor["h"] / 2) / (height * factor),
    }


def image_crop(path, monitor, outputs):
    x, y, width, height = bounds(outputs)
    geometry = [width, height, monitor["w"], monitor["h"], monitor["x"] - x, monitor["y"] - y, monitor["scale"]]
    key = hashlib.sha256((media_key(path) + json.dumps(geometry)).encode()).hexdigest()
    directory = CACHE / "crops"
    directory.mkdir(parents=True, exist_ok=True)
    crop = directory / (key + (".gif" if path.suffix.lower() == ".gif" else ".png"))
    if not crop.exists():
        frames = ["-coalesce"] if path.suffix.lower() == ".gif" else ["+repage"]
        run("magick", str(path), *frames, "-auto-orient", "-resize", f"{width}x{height}^",
            "-gravity", "center", "-extent", f"{width}x{height}", "+repage", "-gravity", "NorthWest",
            "-crop", f"{monitor['w']}x{monitor['h']}+{monitor['x'] - x}+{monitor['y'] - y}",
            "+repage", "-resize", f"{round(monitor['w'] * monitor['scale'])}x{round(monitor['h'] * monitor['scale'])}!", str(crop))
    return crop


def library_files(library):
    # os.walk follows the Home Manager directory symlinks, without recursing into cycles.
    visited = set()
    for directory, children, names in os.walk(library, followlinks=True):
        real = os.path.realpath(directory)
        if real in visited:
            children[:] = []
            continue
        visited.add(real)
        for name in names:
            path = Path(directory) / name
            if not path.is_file() or path.suffix.lower() not in IMAGES | VIDEOS:
                continue
            yield path


def scan():
    state = read_json(CACHE / "state.json", {})
    library = Path.home() / "Pictures/Wallpapers"
    files = []
    for path in library_files(library):
        try:
            preview = thumbnail_path(path)
            files.append(dict(path=str(path), name=str(path.relative_to(library)),
                              thumbnail=str(preview), thumbnailReady=preview.is_file(),
                              video=path.suffix.lower() in VIDEOS))
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            print(f"Skipping {path}: {error}", file=sys.stderr)
    try:
        outputs = monitors()
    except (OSError, ValueError, subprocess.SubprocessError):
        outputs = []
    labels = ["Left", "Center", "Right"] if len(outputs) == 3 else [m["name"] for m in outputs]
    colors = CONFIG / "rofi/colors.rasi"
    current = CACHE / "current"
    return dict(files=sorted(files, key=lambda f: f["name"].lower()),
                layout=state.get("layout", state.get("last", {}).get("layout", "repeat")),
                current=state.get("current", current.read_text().strip() if current.exists() else ""),
                colors=colors.read_text() if colors.exists() else "",
                screens=[dict(label=f"{label} ({m['name']})", target=m["name"]) for label, m in zip(labels, outputs)])


def ipc(path, command):
    with socket.socket(socket.AF_UNIX) as client:
        client.settimeout(1)
        client.connect(str(path))
        client.sendall((json.dumps({"command": command, "request_id": 1}) + "\n").encode())
        with client.makefile("r") as stream:
            for line in stream:
                response = json.loads(line)
                if response.get("request_id") == 1:
                    if response.get("error") != "success":
                        raise ValueError(f"mpv: {response.get('error')}")
                    return response.get("data")
    raise OSError("mpv closed its control socket")


def die_with_parent():
    # A killed controller must not leave video players covering static wallpapers.
    ctypes.CDLL(None).prctl(1, signal.SIGTERM)


class Controller:
    def __init__(self):
        self.state = read_json(CACHE / "state.json", {"assignments": {}})
        self.players = {}
        self.rendered = {}
        self.awww = None

    def stop(self, name):
        player = self.players.pop(name, None)
        if player:
            player["process"].terminate()
            try:
                player["process"].wait(timeout=3)
            except subprocess.TimeoutExpired:
                player["process"].kill()
                player["process"].wait()
            player["socket"].unlink(missing_ok=True)

    def close(self):
        for name in list(self.players):
            self.stop(name)
        if self.awww:
            self.awww.terminate()
            self.awww.wait(timeout=3)

    def ensure_awww(self):
        try:
            run("awww", "query")
            return
        except subprocess.SubprocessError:
            if self.awww is None or self.awww.poll() is not None:
                self.awww = subprocess.Popen(["awww-daemon"], stdout=sys.stderr, stderr=sys.stderr,
                                             preexec_fn=die_with_parent)
        for _ in range(50):
            try:
                run("awww", "query")
                return
            except subprocess.SubprocessError:
                time.sleep(0.1)
        raise ValueError("The image wallpaper daemon did not start")

    def reconcile(self, state, outputs):
        self.ensure_awww()
        assignments = state.get("assignments", {})
        active = {m["name"]: m for m in outputs if m["name"] in assignments}
        for name in set(self.rendered) - set(active):
            self.stop(name)
            self.rendered.pop(name, None)
        groups = {}
        for name, monitor in active.items():
            groups.setdefault(assignments[name]["group"], []).append(monitor)
        started = []
        for name, monitor in active.items():
            choice = assignments[name]
            path = Path(choice["path"])
            if not path.is_file():
                self.stop(name)
                self.rendered.pop(name, None)
                continue
            group = groups[choice["group"]]
            geometry = [(m["name"], m["x"], m["y"], m["w"], m["h"], m["scale"]) for m in
                        (group if choice["layout"] == "span" else [monitor])]
            signature = (media_key(path), choice["layout"], choice["group"], geometry)
            if self.rendered.get(name) == signature and (name not in self.players or self.players[name]["process"].poll() is None):
                continue
            video = path.suffix.lower() in VIDEOS
            image = poster(path)
            if choice["layout"] == "span":
                image = image_crop(image, monitor, group)
            # The cached frame remains underneath video as a fallback.
            run("awww", "img", str(image), "--outputs", name, "--resize", "crop",
                "--transition-type", "grow", "--transition-pos", "0.5,0.0", "--transition-fps", "60")
            self.stop(name)
            if video:
                control = RUNTIME / (hashlib.sha256(name.encode()).hexdigest()[:12] + ".sock")
                control.unlink(missing_ok=True)
                options = f"config=no terminal=no hwdec=auto audio=no loop-file=inf pause=yes panscan=1 osc=no osd-level=0 input-ipc-server={control}"
                process = subprocess.Popen(["mpvpaper", "-l", "bottom", "-o", options, name, str(path)],
                                           stdin=subprocess.DEVNULL, stdout=sys.stderr, stderr=sys.stderr,
                                           preexec_fn=die_with_parent)
                self.players[name] = dict(process=process, socket=control, group=choice["group"], paused=True)
                deadline = time.monotonic() + 15
                while True:
                    if process.poll() is not None:
                        raise ValueError(f"Video wallpaper failed to start on {name}; see wallpaper-picker/manager.log")
                    try:
                        dimensions = ipc(control, ["get_property", "video-out-params"])
                        if dimensions:
                            break
                    except (OSError, ValueError):
                        pass
                    if time.monotonic() > deadline:
                        raise ValueError(f"Timed out loading video on {name}")
                    time.sleep(0.05)
                if choice["layout"] == "span":
                    width, height = dimensions["dw"], dimensions["dh"]
                    if dimensions.get("rotate", 0) % 180 == 90:
                        width, height = height, width
                    osd = ipc(control, ["get_property", "osd-dimensions"])
                    render_size = (osd["w"], osd["h"]) if osd else None
                    for prop, value in video_transform(monitor, group, width, height, render_size).items():
                        ipc(control, ["set_property", prop, value])
                started.append(name)
            self.rendered[name] = signature
        # Wait until every new output is loaded before starting their shared timeline.
        for group_id in {self.players[name]["group"] for name in started}:
            members = [p for p in self.players.values() if p["group"] == group_id]
            leader = next((p for p in members if not p["paused"]), members[0])
            position = ipc(leader["socket"], ["get_property", "time-pos"]) or 0
            for player in members:
                if player["paused"]:
                    ipc(player["socket"], ["seek", position, "absolute+exact"])
            for player in members:
                ipc(player["socket"], ["set_property", "pause", False])
                player["paused"] = False

    def apply(self, path, layout, target):
        outputs = monitors()
        if not outputs:
            raise ValueError("No active monitors")
        path = Path(path).expanduser().absolute()
        if path.is_dir():
            choices = list(library_files(path))
            if not choices:
                raise ValueError("No wallpapers in the selected directory")
            path = random.choice(choices)
        if not path.is_file() or path.suffix.lower() not in IMAGES | VIDEOS:
            raise ValueError("Select a supported image or video file")
        layout = layout or self.state.get("layout", self.state.get("last", {}).get("layout", "repeat"))
        target = target or "all"
        if layout not in {"repeat", "span"}:
            raise ValueError("Layout must be repeat or span")
        selected = outputs if target == "all" else [m for m in outputs if m["name"] == target]
        if not selected:
            raise ValueError(f"Monitor {target} is disconnected")
        if layout == "span" and len(selected) < 2:
            raise ValueError("Span requires at least two monitors; select All screens")
        image = poster(path)
        state = json.loads(json.dumps(self.state))
        choice = dict(path=str(path), layout=layout, target=target, group=uuid.uuid4().hex)
        state.setdefault("assignments", {}).update({m["name"]: choice for m in selected})
        state.pop("preferences", None)
        state.update(current=str(path), last=choice, layout=layout)
        try:
            self.reconcile(state, outputs)
        except Exception:
            # Restore the preceding choices; never mark a failed selection as current.
            for name in list(self.players):
                self.stop(name)
            self.rendered.clear()
            try:
                self.reconcile(self.state, outputs)
            except Exception as error:
                print(f"Wallpaper rollback: {error}", file=sys.stderr)
            raise
        save_state(state)
        self.state = state
        return dict(path=str(path), image=str(image), theme_key=media_key(path), layout=layout, target=target)

    def tick(self):
        outputs = monitors()
        last = self.state.get("last", {})
        if last.get("target") == "all":
            for monitor in outputs:
                self.state.setdefault("assignments", {}).setdefault(monitor["name"], last)
        self.reconcile(self.state, outputs)
        if not self.players:
            return
        clients = json.loads(run("hyprctl", "clients", "-j"))
        locked = subprocess.run(["pgrep", "-x", "hyprlock"], stdout=subprocess.DEVNULL).returncode == 0
        hidden = {m["name"] for m in outputs if not m.get("dpmsStatus", True) or any(
            c.get("monitor") == m["id"] and c.get("fullscreen", 0) >= 2
            and c.get("workspace", {}).get("id") == m["activeWorkspace"]["id"] for c in clients)}
        groups = {}
        for name, player in self.players.items():
            groups.setdefault(player["group"], []).append((name, player))
        for members in groups.values():
            # Pause a panorama together so an exposed output never loses its timeline.
            paused = locked or all(name in hidden for name, _ in members)
            for _, player in members:
                if player["paused"] != paused:
                    ipc(player["socket"], ["set_property", "pause", paused])
                    player["paused"] = paused
            if not paused and len(members) > 1:
                position = ipc(members[0][1]["socket"], ["get_property", "time-pos"])
                for _, player in members[1:]:
                    other = ipc(player["socket"], ["get_property", "time-pos"])
                    if position is not None and other is not None and abs(position - other) > 0.12:
                        ipc(player["socket"], ["seek", position, "absolute+exact"])


def daemon():
    RUNTIME.mkdir(mode=0o700, parents=True, exist_ok=True)
    # The lock prevents keybinds and session startup from creating duplicate controllers.
    with (RUNTIME / "manager.lock").open("w") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        address = RUNTIME / "manager.sock"
        address.unlink(missing_ok=True)
        controller = Controller()
        signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
        signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
        try:
            with socket.socket(socket.AF_UNIX) as server:
                server.bind(str(address))
                server.listen()
                server.settimeout(0.5)
                next_tick = 0
                while True:
                    try:
                        client, _ = server.accept()
                    except socket.timeout:
                        client = None
                    if client:
                        with client:
                            client.settimeout(120)
                            try:
                                with client.makefile("r") as stream:
                                    request = json.loads(stream.readline())
                                result = controller.apply(request["path"], request.get("layout"), request.get("target"))
                                response = dict(ok=True, **result)
                            except Exception as error:
                                response = dict(ok=False, error=str(error))
                                print(error, file=sys.stderr)
                            try:
                                client.sendall((json.dumps(response) + "\n").encode())
                            except OSError:
                                pass
                    if time.monotonic() >= next_tick:
                        try:
                            controller.tick()
                        except Exception as error:
                            print(f"Wallpaper refresh: {error}", file=sys.stderr)
                        next_tick = time.monotonic() + 2
        finally:
            controller.close()
            address.unlink(missing_ok=True)


def request_apply(args):
    RUNTIME.mkdir(mode=0o700, parents=True, exist_ok=True)
    address = RUNTIME / "manager.sock"
    try:
        client = socket.socket(socket.AF_UNIX)
        client.connect(str(address))
    except OSError:
        client.close()
        CACHE.mkdir(parents=True, exist_ok=True)
        with (CACHE / "manager.log").open("a") as log:
            subprocess.Popen([sys.executable, __file__, "daemon"], stdin=subprocess.DEVNULL,
                             stdout=log, stderr=log, start_new_session=True)
        for _ in range(100):
            time.sleep(0.05)
            client = socket.socket(socket.AF_UNIX)
            try:
                client.connect(str(address))
                break
            except OSError:
                client.close()
        else:
            raise ValueError("Wallpaper manager did not start; see wallpaper-picker/manager.log")
    with client:
        client.settimeout(180)
        client.sendall((json.dumps(dict(path=args.path, layout=args.layout, target=args.target)) + "\n").encode())
        with client.makefile("r") as stream:
            response = json.loads(stream.readline())
    if not response.pop("ok"):
        raise ValueError(response["error"])
    return response


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("scan")
    commands.add_parser("daemon")
    preview = commands.add_parser("thumbnail")
    preview.add_argument("path", type=Path)
    apply = commands.add_parser("apply")
    apply.add_argument("path")
    apply.add_argument("layout", nargs="?", choices=["repeat", "span"])
    apply.add_argument("target", nargs="?")
    args = parser.parse_args()
    try:
        if args.command == "daemon":
            daemon()
        elif args.command == "thumbnail":
            print(json.dumps(dict(path=str(args.path), thumbnail=str(thumbnail(args.path)))))
        else:
            print(json.dumps(scan() if args.command == "scan" else request_apply(args)))
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
