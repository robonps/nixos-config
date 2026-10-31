#!/usr/bin/env python3
"""Wallpaper library and session-owned renderers, with optional packaged providers."""

import argparse
from contextlib import contextmanager
import ctypes
import fcntl
import hashlib
import importlib.util
import json
import math
import os
from pathlib import Path
import random
import signal
import socket
import select
import struct
import subprocess
import sys
import time
import uuid
from functools import lru_cache


IMAGES = {".jpg", ".jpeg", ".png", ".webp", ".gif"}
VIDEOS = {".mp4", ".webm", ".mkv", ".mov", ".m4v"}
# Hyprland's layer entry animation is 350 ms in this configuration. Its layer IPC
# can report the target alpha before the visible fade finishes, so allow it to settle.
HANDOFF_SETTLE_SECONDS = 0.4
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


@lru_cache(maxsize=1)
def providers():
    """Only load modules explicitly registered by the Nix wrapper, never library contents."""
    manifest = os.environ.get("WALLPAPER_PROVIDER_MANIFEST")
    result = {}
    for entry in read_json(Path(manifest), []) if manifest else []:
        try:
            spec = importlib.util.spec_from_file_location(f"wallpaper_provider_{entry['id']}", entry["module"])
            module = importlib.util.module_from_spec(spec)
            spec.loader.exec_module(module)
            result[entry["id"]] = module.Provider(entry["settings"])
        except Exception as error:
            # An optional provider must not take the local wallpaper library down with it.
            print(f"Wallpaper provider unavailable: {error}", file=sys.stderr)
    return result


def preferences():
    data = read_json(CONFIG / "wallpaper-picker/preferences.json", {})
    return data if isinstance(data, dict) else {}


def set_view(view):
    if view not in {"all", "local", *providers()}:
        raise ValueError("Unknown wallpaper view")
    path = CONFIG / "wallpaper-picker/preferences.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.with_suffix(".lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        data = dict(preferences(), view=view)
        temporary = path.with_name(f".{path.name}.{uuid.uuid4().hex}.tmp")
        try:
            with temporary.open("x") as stream:
                json.dump(data, stream)
                stream.flush()
                os.fsync(stream.fileno())
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)
    return data


def resolve_asset(path):
    path = Path(path).expanduser().absolute()
    for provider in providers().values():
        asset = provider.resolve(path)
        if asset is not None:
            return asset
    if path.is_dir():
        choices = list(library_files(path))
        if not choices:
            raise ValueError("No wallpapers in the selected directory")
        path = random.choice(choices)
    if not path.is_file() or path.suffix.lower() not in IMAGES | VIDEOS:
        raise ValueError("Select a supported wallpaper; its provider may be disabled or unavailable")
    video = path.suffix.lower() in VIDEOS
    return dict(path=str(path), media_path=str(path), image=None, origin="local",
                renderer="mpvpaper" if video else "awww", video=video)


def asset_key(asset):
    if asset.get("origin", "local") == "local":
        return media_key(Path(asset["path"]))
    keys = [media_key(Path(asset[field])) for field in ("path", "media_path", "image") if asset.get(field)]
    return hashlib.sha256("\0".join(keys).encode()).hexdigest()


def asset_image(asset):
    if asset.get("origin", "local") == "local":
        return poster(Path(asset["media_path"]))
    source = asset.get("image")
    if not source:
        return None
    source = Path(source)
    directory = CACHE / "previews"
    directory.mkdir(parents=True, exist_ok=True)
    destination = directory / f"{media_key(source)}.png"
    if not cached_file(destination):
        temporary = destination.with_suffix(f".{uuid.uuid4().hex}.png")
        try:
            run("magick", f"{source}[0]", "-auto-orient", "-resize", "1920x1080>", str(temporary))
            temporary.replace(destination)
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            print(f"Wallpaper preview unavailable: {error}", file=sys.stderr)
            return None
        finally:
            temporary.unlink(missing_ok=True)
    return destination


def save_state(state):
    CACHE.mkdir(parents=True, exist_ok=True)
    temporary = CACHE / "state.tmp"
    temporary.write_text(json.dumps(state))
    temporary.replace(CACHE / "state.json")
    (CACHE / "current").write_text(state.get("current", "") + "\n")


def media_key(path):
    stat = path.stat()
    return hashlib.sha256(f"{path}\0{stat.st_size}\0{stat.st_mtime_ns}".encode()).hexdigest()


def cached_file(path):
    """Keep recently used generated files alive without writing on every scan."""
    try:
        stat = path.stat()
        if not path.is_file():
            return False
        if time.time() - stat.st_mtime > 86400:
            path.touch()
        return True
    except OSError:
        return False


def prune_cache():
    """Only expire generated media/metadata; never remove playback state or logs."""
    CACHE.mkdir(parents=True, exist_ok=True)
    with (CACHE / "cleanup.lock").open("a") as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        marker = CACHE / "cleanup.stamp"
        now = time.time()
        if marker.exists() and now - marker.stat().st_mtime < 86400:
            return
        state = read_json(CACHE / "state.json", {})
        protected = {Path(choice["image"]).resolve()
                     for choice in [*state.get("assignments", {}).values(), state.get("last", {})]
                     if isinstance(choice, dict) and choice.get("image")}
        for name in ("resolutions", "thumbnails", "frames", "previews", "crops"):
            directory = CACHE / name
            if not directory.is_dir() or directory.is_symlink():
                continue
            for path in directory.iterdir():
                try:
                    if (path.is_file() and not path.is_symlink() and path.resolve() not in protected
                            and now - path.stat().st_mtime > 30 * 86400):
                        path.unlink(missing_ok=True)
                except OSError:
                    continue
        marker.touch()


def schedule_cache_cleanup():
    try:
        marker = CACHE / "cleanup.stamp"
        if marker.exists() and time.time() - marker.stat().st_mtime < 86400:
            return
        # Scanning has already refreshed cache usage. Do maintenance separately
        # so neither picker startup nor its stdout pipe waits for deletion.
        subprocess.Popen([sys.executable, __file__, "prune-cache"], stdin=subprocess.DEVNULL,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
    except OSError:
        pass


def poster(path):
    if path.suffix.lower() not in VIDEOS:
        return path
    directory = CACHE / "frames"
    directory.mkdir(parents=True, exist_ok=True)
    frame = directory / f"{media_key(path)}.jpg"
    if not cached_file(frame):
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
    asset = resolve_asset(path)
    if asset.get("origin", "local") != "local":
        # Bundled project previews are also used for Workshop videos: no frame extraction.
        return thumbnail(Path(asset["image"])) if asset.get("image") else None
    destination = thumbnail_path(path)
    if cached_file(destination):
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


def resolution_key(asset):
    # Include project metadata as well as the media: a project can change source
    # without changing its identity. Bump the version when dimension parsing changes.
    paths = dict.fromkeys([asset["path"], asset.get("media_path", asset["path"])])
    parts = ["resolution-v1", asset.get("origin", "local"), asset.get("kind", "")]
    return hashlib.sha256("\0".join(parts + [media_key(Path(path)) for path in paths]).encode()).hexdigest()


def cached_resolution(key):
    path = CACHE / "resolutions" / f"{key}.json"
    data = read_json(path, None)
    if not isinstance(data, dict) or "resolution" not in data:
        return None
    size = data["resolution"]
    if size is None:
        # Retry unknown dimensions after five minutes, independently of the
        # file's usage timestamp (which keeps useful cache entries alive).
        checked = data.get("checked")
        if not isinstance(checked, (int, float)) or time.time() - checked > 300:
            return None
    elif not (isinstance(size, list) and len(size) == 2
              and all(type(value) is int and value > 0 for value in size)):
        return None
    return data if cached_file(path) else None


def probe_resolution(asset):
    """Read source dimensions independently of cropped picker previews."""
    try:
        media = Path(asset["media_path"])
        if asset.get("origin", "local") != "local" and not asset.get("video"):
            provider = providers()[asset["provider"]]
            size = provider.resolution(asset) if hasattr(provider, "resolution") else None
        elif media.suffix.lower() in VIDEOS:
            result = subprocess.run([
                "ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries",
                "stream=width,height:stream_tags=rotate:stream_side_data=rotation", "-of", "json", str(media),
            ], check=True, capture_output=True, text=True, timeout=5)
            stream = json.loads(result.stdout)["streams"][0]
            size = [stream["width"], stream["height"]]
            rotation = next((item["rotation"] for item in stream.get("side_data_list", [])
                             if "rotation" in item), stream.get("tags", {}).get("rotate", 0))
            if float(rotation) % 180 == 90:
                size.reverse()
        else:
            result = subprocess.run([
                "magick", "identify", "-ping", "-format", "%w %h %[orientation]", f"{media}[0]",
            ], check=True, capture_output=True, text=True, timeout=5)
            width, height, *orientation = result.stdout.split()
            size = [int(width), int(height)]
            if orientation and orientation[0] in {"LeftTop", "RightTop", "RightBottom", "LeftBottom"}:
                size.reverse()
        if size and len(size) == 2 and all(not isinstance(v, bool) and int(v) > 0 for v in size):
            return [int(v) for v in size]
    except (OSError, ValueError, TypeError, KeyError, IndexError, subprocess.SubprocessError):
        pass
    return None


def metadata(path):
    result = dict(path=str(path), resolution=None)
    try:
        asset = resolve_asset(path)
        key = resolution_key(asset)
        result["metadataKey"] = key
        cached = cached_resolution(key)
        if cached is not None:
            result["resolution"] = cached["resolution"]
            return result
        result["resolution"] = probe_resolution(asset)
        destination = CACHE / "resolutions" / f"{key}.json"
        temporary = destination.with_suffix(f".{uuid.uuid4().hex}.tmp")
        try:
            destination.parent.mkdir(parents=True, exist_ok=True)
            temporary.write_text(json.dumps(dict(resolution=result["resolution"], checked=time.time())))
            temporary.replace(destination)
        finally:
            temporary.unlink(missing_ok=True)
    except (OSError, ValueError, TypeError, KeyError, subprocess.SubprocessError):
        # Cache failures must not hide dimensions successfully read from the source.
        pass
    return result


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
    if not cached_file(crop):
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
                              thumbnail=str(preview), thumbnailReady=cached_file(preview),
                              video=path.suffix.lower() in VIDEOS, origin="local",
                              renderer="mpvpaper" if path.suffix.lower() in VIDEOS else "awww"))
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            print(f"Skipping {path}: {error}", file=sys.stderr)
    for provider in providers().values():
        try:
            for asset in provider.scan():
                preview = thumbnail_path(Path(asset["image"])) if asset.get("image") else None
                files.append(dict(asset, thumbnail=str(preview) if preview else "",
                                  thumbnailReady=not preview or cached_file(preview)))
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            print(f"Wallpaper library unavailable: {error}", file=sys.stderr)
    for asset in files:
        try:
            asset["metadataKey"] = resolution_key(asset)
            cached = cached_resolution(asset["metadataKey"])
            if cached is not None:
                asset["resolution"] = cached["resolution"]
        except (OSError, ValueError, KeyError):
            continue
    try:
        outputs = monitors()
    except (OSError, ValueError, subprocess.SubprocessError):
        outputs = []
    labels = ["Left", "Center", "Right"] if len(outputs) == 3 else [m["name"] for m in outputs]
    colors = CONFIG / "rofi/colors.rasi"
    current = CACHE / "current"
    return dict(files=sorted(files, key=lambda f: f["name"].lower()),
                views=([dict(id="all", label="All"), dict(id="local", label="Wallpapers")]
                       + [dict(id=p.id, label=p.label) for p in providers().values()]) if providers() else [],
                view=preferences().get("view", "all"), errors=read_json(RUNTIME / "errors.json", []),
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
        self.external = {}
        self.failures = {}
        self.pending_group = None
        self.last_errors = None

    def stop_external(self, key):
        item = self.external.pop(key, None)
        if item:
            item["renderer"].stop()

    def record_failure(self, key, signature, names, error):
        failure = dict(signature=signature, outputs=names, error=str(error))
        if self.failures.get(key) != failure:
            print(f"Wallpaper on {', '.join(names)}: {error}", file=sys.stderr)
        self.failures[key] = failure

    def publish_errors(self):
        errors = [failure["error"] for failure in self.failures.values()]
        if errors != self.last_errors:
            RUNTIME.mkdir(mode=0o700, parents=True, exist_ok=True)
            temporary = RUNTIME / "errors.tmp"
            temporary.write_text(json.dumps(errors))
            temporary.replace(RUNTIME / "errors.json")
            self.last_errors = errors

    def stop(self, name):
        player = self.players.pop(name, None)
        self.stop_player(player)

    @staticmethod
    def stop_player(player):
        if player:
            player["process"].terminate()
            try:
                player["process"].wait(timeout=3)
            except subprocess.TimeoutExpired:
                player["process"].kill()
                player["process"].wait()
            player["socket"].unlink(missing_ok=True)

    def close(self):
        for key in list(self.external):
            self.stop_external(key)
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

    def start_video(self, name, path, choice, monitor, group):
        # Old and new players overlap during the handoff; neither may unlink the other's IPC socket.
        control = RUNTIME / f"{hashlib.sha256(name.encode()).hexdigest()[:12]}-{uuid.uuid4().hex[:8]}.sock"
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

    def reconcile(self, state, outputs):
        retired_players, retired_external = {}, {}
        previous_live = set(self.players)
        previous_live.update(m["name"] for item in self.external.values() for m in item["outputs"])
        try:
            self.reconcile_renderers(state, outputs, retired_players, retired_external, previous_live)
        finally:
            # Keep the preceding wallpaper underneath the incoming renderer until its layer is fully mapped.
            # This also cleans up retired processes before the existing apply rollback runs on failure.
            for player in retired_players.values():
                self.stop_player(player)
            for item in retired_external.values():
                item["renderer"].stop()

    def wait_for_video_surfaces(self, names):
        deadline = time.monotonic() + 15
        while True:
            layers = json.loads(run("hyprctl", "layers", "-j"))
            ready = True
            for name in names:
                process = self.players[name]["process"]
                if process.poll() is not None:
                    raise ValueError(f"Video wallpaper failed to present on {name}")
                if not any(layer.get("namespace") == "mpvpaper" and layer.get("pid") == process.pid
                           and layer.get("alpha", 0) >= 0.99 and layer.get("w", 0) > 0 and layer.get("h", 0) > 0
                           for entries in layers.get(name, {}).get("levels", {}).values() for layer in entries):
                    ready = False
            if ready:
                return
            if time.monotonic() >= deadline:
                raise ValueError("Video wallpaper did not present its desktop surfaces")
            time.sleep(0.05)

    def reconcile_renderers(self, state, outputs, retired_players, retired_external, previous_live):
        self.ensure_awww()
        assignments = state.get("assignments", {})
        active = {m["name"]: m for m in outputs if m["name"] in assignments}
        for name in set(self.rendered) - set(active):
            self.stop(name)
            self.rendered.pop(name, None)
        groups = {}
        for name, monitor in active.items():
            groups.setdefault(assignments[name]["group"], []).append(monitor)
        assets, desired = {}, {}
        for name, monitor in active.items():
            choice = assignments[name]
            try:
                asset = resolve_asset(choice["path"])
                asset_key(asset)
                assets[name] = asset
                if asset["renderer"] not in {"awww", "mpvpaper"}:
                    members = groups[choice["group"]] if choice["layout"] == "span" else [monitor]
                    key = f"span-{choice['group']}" if choice["layout"] == "span" else name
                    geometry = [(m["name"], m["x"], m["y"], m["w"], m["h"], m["scale"]) for m in members]
                    signature = (asset_key(asset), choice["group"], geometry)
                    desired[key] = dict(asset=asset, outputs=members, signature=signature, group=choice["group"])
                self.failures.pop(f"missing-{name}", None)
            except (OSError, ValueError) as error:
                if choice["group"] == self.pending_group:
                    raise
                self.record_failure(f"missing-{name}", choice["path"], [name], error)
        for key, item in list(self.external.items()):
            wanted = desired.get(key)
            if not item["renderer"].alive() and wanted:
                self.record_failure(key, wanted["signature"], [m["name"] for m in wanted["outputs"]],
                                    "Wallpaper renderer stopped unexpectedly; select it again to retry")
            if not wanted or wanted["signature"] != item["signature"] or not item["renderer"].alive():
                retired_external[key] = self.external.pop(key)
        for key, failure in list(self.failures.items()):
            if not set(failure["outputs"]) & set(active):
                del self.failures[key]
        started, new_external, pending_previews = [], [], []
        for name, monitor in active.items():
            choice = assignments[name]
            asset = assets.get(name)
            if asset is None:
                if name in self.players:
                    retired_players[name] = self.players.pop(name)
                image = choice.get("image")
                members = groups[choice["group"]] if choice["layout"] == "span" else [monitor]
                fallback = ("fallback", image, [(m["name"], m["x"], m["y"], m["w"], m["h"], m["scale"]) for m in members])
                if image and Path(image).is_file() and self.rendered.get(name) != fallback:
                    if choice["layout"] == "span":
                        image = image_crop(Path(image), monitor, members)
                    run("awww", "img", str(image), "--outputs", name, "--resize", "crop", "--transition-type", "none")
                self.rendered[name] = fallback
                continue
            path = Path(asset["media_path"])
            group = groups[choice["group"]]
            geometry = [(m["name"], m["x"], m["y"], m["w"], m["h"], m["scale"]) for m in
                        (group if choice["layout"] == "span" else [monitor])]
            signature = (asset_key(asset), choice["layout"], choice["group"], geometry)
            if self.rendered.get(name) == signature and (name not in self.players or self.players[name]["process"].poll() is None):
                continue
            if asset.get("provider") and name in self.players and self.players[name]["process"].poll() is not None:
                self.record_failure(f"video-{name}", signature, [name],
                                    "Video renderer stopped unexpectedly; select it again to retry")
                self.stop(name)
                continue
            video = asset["renderer"] == "mpvpaper"
            image = asset_image(asset)
            if image and choice["layout"] == "span":
                image = image_crop(image, monitor, group)
            animated = asset["renderer"] != "awww"
            # Previews are recovery backdrops, not an intermediate wallpaper during a live handoff.
            if image:
                if animated:
                    pending_previews.append((name, image))
                else:
                    run("awww", "img", str(image), "--outputs", name, "--resize", "crop",
                        "--transition-type", "none" if name in previous_live else "grow",
                        "--transition-pos", "0.5,0.0", "--transition-fps", "60")
            if name in self.players:
                retired_players[name] = self.players.pop(name)
            if video:
                failure_key = f"video-{name}"
                if self.failures.get(failure_key, {}).get("signature") == signature:
                    continue
                try:
                    self.start_video(name, path, choice, monitor, group)
                    self.failures.pop(failure_key, None)
                except (OSError, ValueError, subprocess.SubprocessError) as error:
                    self.stop(name)
                    if not asset.get("provider") or choice["group"] == self.pending_group:
                        raise
                    self.record_failure(failure_key, signature, [name], error)
                    continue
                started.append(name)
            self.rendered[name] = signature
        for key, wanted in desired.items():
            if key in self.external:
                continue
            if self.failures.get(key, {}).get("signature") == wanted["signature"]:
                continue
            try:
                renderer = providers()[wanted["asset"]["renderer"]].start(
                    wanted["asset"], wanted["outputs"], RUNTIME, die_with_parent)
                self.external[key] = dict(wanted, renderer=renderer)
                new_external.append(renderer)
                self.failures.pop(key, None)
            except (OSError, ValueError, subprocess.SubprocessError) as error:
                self.record_failure(key, wanted["signature"], [m["name"] for m in wanted["outputs"]], error)
                if wanted["group"] == self.pending_group:
                    raise
        self.publish_errors()
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
        if started:
            self.wait_for_video_surfaces(started)
        if started or new_external:
            time.sleep(HANDOFF_SETTLE_SECONDS)
            if any(self.players[name]["process"].poll() is not None for name in started) \
                    or any(not renderer.alive() for renderer in new_external):
                raise ValueError("Wallpaper renderer stopped during the handoff")
        # Update fallback art only after the live renderer covers it, without animating the hidden layer.
        for name, image in pending_previews:
            run("awww", "img", str(image), "--outputs", name, "--resize", "crop", "--transition-type", "none")

    def apply(self, path, layout, target):
        outputs = monitors()
        if not outputs:
            raise ValueError("No active monitors")
        asset = resolve_asset(path)
        path = Path(asset["path"])
        layout = layout or self.state.get("layout", self.state.get("last", {}).get("layout", "repeat"))
        target = target or "all"
        if layout not in {"repeat", "span"}:
            raise ValueError("Layout must be repeat or span")
        selected = outputs if target == "all" else [m for m in outputs if m["name"] == target]
        if not selected:
            raise ValueError(f"Monitor {target} is disconnected")
        if layout == "span" and len(selected) < 2:
            raise ValueError("Span requires at least two monitors; select All screens")
        image = asset_image(asset)
        state = json.loads(json.dumps(self.state))
        choice = dict(path=str(path), layout=layout, target=target, group=uuid.uuid4().hex)
        if asset.get("origin", "local") != "local":
            choice.update(provider=asset["provider"], image=str(image) if image else None)
        state.setdefault("assignments", {}).update({m["name"]: choice for m in selected})
        state.pop("preferences", None)
        state.update(current=str(path), last=choice, layout=layout)
        self.pending_group = choice["group"]
        names = {m["name"] for m in selected}
        self.failures = {key: f for key, f in self.failures.items() if not names.intersection(f["outputs"])}
        try:
            self.reconcile(state, outputs)
        except Exception:
            # Restore the preceding choices; never mark a failed selection as current.
            for name in list(self.players):
                self.stop(name)
            for key in list(self.external):
                self.stop_external(key)
            self.rendered.clear()
            self.pending_group = None
            try:
                self.reconcile(self.state, outputs)
            except Exception as error:
                print(f"Wallpaper rollback: {error}", file=sys.stderr)
            raise
        finally:
            self.pending_group = None
        save_state(state)
        self.state = state
        return dict(path=str(path), name=asset.get("name", path.name), image=str(image) if image else None,
                    theme_key=asset_key(asset) if image else None, layout=layout, target=target)

    def tick(self):
        outputs = monitors()
        last = self.state.get("last", {})
        if last.get("target") == "all":
            for monitor in outputs:
                self.state.setdefault("assignments", {}).setdefault(monitor["name"], last)
        self.reconcile(self.state, outputs)
        if not self.players and not self.external:
            return
        clients = json.loads(run("hyprctl", "clients", "-j"))
        locked = subprocess.run(["pgrep", "-x", "hyprlock"], stdout=subprocess.DEVNULL).returncode == 0
        hidden = {m["name"] for m in outputs if not m.get("dpmsStatus", True) or any(
            c.get("monitor") == m["id"] and c.get("fullscreen", 0) >= 2
            and c.get("workspace", {}).get("id") == m["activeWorkspace"]["id"] for c in clients)}
        groups = {}
        for name, player in self.players.items():
            groups.setdefault(player["group"], []).append((name, player))
        for item in self.external.values():
            group_names = [m["name"] for m in outputs
                           if self.state.get("assignments", {}).get(m["name"], {}).get("group") == item["group"]]
            item["renderer"].set_paused(locked or all(name in hidden for name in group_names))
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
        identity = manager_identity()
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
                                if request.get("op", "apply") == "status":
                                    result = identity
                                elif request.get("op", "apply") == "apply":
                                    result = controller.apply(request["path"], request.get("layout"), request.get("target"))
                                else:
                                    raise ValueError("Unknown wallpaper manager operation")
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


def manager_identity():
    manifest = os.environ.get("WALLPAPER_PROVIDER_MANIFEST", "")
    fingerprint = b"\0".join([str(Path(__file__).resolve()).encode(), Path(__file__).read_bytes(),
                               str(Path(sys.executable).resolve()).encode(),
                               os.environ.get("WALLPAPER_MANAGER_BUILD", "").encode(),
                               manifest.encode(), Path(manifest).read_bytes() if manifest else b""])
    return dict(protocol=1, generation=hashlib.sha256(fingerprint).hexdigest())


def connect_manager():
    client = socket.socket(socket.AF_UNIX)
    client.settimeout(180)
    try:
        client.connect(str(RUNTIME / "manager.sock"))
        return client
    except BaseException:
        client.close()
        raise


def exchange(client, request):
    client.sendall((json.dumps(request) + "\n").encode())
    with client.makefile("r") as stream:
        response = json.loads(stream.readline())
    if not isinstance(response, dict):
        raise ValueError("Invalid wallpaper manager response")
    return response


def stop_stale_manager(client):
    """Address the socket's verified owner, never a name-based process search."""
    pid, uid, _ = struct.unpack("3i", client.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12))
    if uid != os.getuid() or pid <= 1 or pid == os.getpid():
        raise ValueError("Cannot verify the old wallpaper manager's owner; restart the desktop session")
    try:
        descriptor = os.pidfd_open(pid)
    except ProcessLookupError:
        return
    try:
        process = Path(f"/proc/{pid}")
        args = process.joinpath("cmdline").read_bytes().rstrip(b"\0").split(b"\0")
        environment = dict(item.split(b"=", 1) for item in process.joinpath("environ").read_bytes().split(b"\0") if b"=" in item)
        script = Path(os.fsdecode(args[1])) if len(args) == 3 else Path("")
        same_session = environment.get(b"HYPRLAND_INSTANCE_SIGNATURE", b"default") == os.fsencode(
            os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "default"))
        same_runtime = environment.get(b"XDG_RUNTIME_DIR", f"/run/user/{uid}".encode()) == os.fsencode(
            os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{uid}"))
        if not (len(args) == 3 and args[2] == b"daemon" and same_session and same_runtime
                and (script.name == "wallpaper-manager.py" or script.name.endswith("-wallpaper-manager.py"))):
            raise ValueError("Cannot verify the old wallpaper manager's session; restart the desktop session")
        signal.pidfd_send_signal(descriptor, signal.SIGTERM)
        if not select.select([descriptor], [], [], 30)[0]:
            raise ValueError("The old wallpaper manager did not finish cleanup; see wallpaper-picker/manager.log")
    except ProcessLookupError:
        pass
    finally:
        os.close(descriptor)


@contextmanager
def current_manager():
    """Serialize generation changes and applies, including the first legacy upgrade."""
    RUNTIME.mkdir(mode=0o700, parents=True, exist_ok=True)
    with (RUNTIME / "handoff.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            client = connect_manager()
        except (FileNotFoundError, ConnectionRefusedError):
            client = None
        if client:
            with client:
                status = exchange(client, dict(op="status"))
                # Legacy daemons respond with an ordinary missing-'path' error.
                if any(status.get(key) != value for key, value in manager_identity().items()):
                    stop_stale_manager(client)
                    client = None
        if client is None:
            CACHE.mkdir(parents=True, exist_ok=True)
            with (CACHE / "manager.log").open("a") as log:
                subprocess.Popen([sys.executable, __file__, "daemon"], stdin=subprocess.DEVNULL,
                                 stdout=log, stderr=log, start_new_session=True)
            for _ in range(100):
                try:
                    with connect_manager() as probe:
                        status = exchange(probe, dict(op="status"))
                    if all(status.get(key) == value for key, value in manager_identity().items()):
                        break
                except (FileNotFoundError, ConnectionRefusedError):
                    pass
                time.sleep(0.05)
            else:
                raise ValueError("Wallpaper manager did not start; see wallpaper-picker/manager.log")
        with connect_manager() as client:
            yield client


def request_apply(args):
    with current_manager() as client:
        response = exchange(client, dict(path=args.path, layout=args.layout, target=args.target))
    if not response.pop("ok"):
        raise ValueError(response["error"])
    return response


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    commands.add_parser("scan")
    commands.add_parser("prune-cache", help="Expire unused generated cache files in the background")
    commands.add_parser("daemon")
    commands.add_parser("status", help="Ensure the current manager build is running and report its identity")
    preview = commands.add_parser("thumbnail")
    preview.add_argument("path", type=Path)
    metadata_command = commands.add_parser("metadata", help="Report source dimensions without rendering a wallpaper")
    metadata_command.add_argument("path", type=Path)
    view = commands.add_parser("view", help="Persist the picker view independently of playback")
    view.add_argument("view")
    apply = commands.add_parser("apply")
    apply.add_argument("path")
    apply.add_argument("layout", nargs="?", choices=["repeat", "span"])
    apply.add_argument("target", nargs="?")
    args = parser.parse_args()
    try:
        if args.command == "daemon":
            daemon()
        elif args.command == "status":
            with current_manager() as client:
                print(json.dumps(exchange(client, dict(op="status"))))
        elif args.command == "thumbnail":
            preview = thumbnail(args.path)
            print(json.dumps(dict(path=str(args.path), thumbnail=str(preview) if preview else "")))
        elif args.command == "metadata":
            print(json.dumps(metadata(args.path)))
        elif args.command == "prune-cache":
            prune_cache()
        elif args.command == "view":
            print(json.dumps(set_view(args.view)))
        else:
            print(json.dumps(scan() if args.command == "scan" else request_apply(args)))
            if args.command == "scan":
                schedule_cache_cleanup()
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(str(error), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
