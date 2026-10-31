"""Workshop discovery and the native linux-wallpaperengine process adapter."""

import json
import os
from pathlib import Path
import re
import signal
import struct
import subprocess
import sys
import time
from functools import lru_cache


PREVIEWS = ("preview.jpg", "preview.png", "preview.jpeg", "preview.gif", "preview.webp")
IMAGES = {".jpg", ".jpeg", ".png", ".gif", ".webp"}
VIDEOS = {".mp4", ".webm", ".mkv", ".mov", ".m4v"}
VDF_TOKEN = re.compile(r'\s+|//[^\n]*|"(?:\\.|[^"\\])*"|[{}]|[^\s{}"]+')


@lru_cache(maxsize=64)
def parse_vdf(path, modified, size):
    """Read Steam's small KeyValues files; the stat arguments invalidate the cache."""
    if size > 1024 * 1024:
        raise ValueError("Steam metadata exceeds 1 MiB")
    source = path.read_text(encoding="utf-8-sig")
    tokens, position = [], 0
    while position < len(source):
        match = VDF_TOKEN.match(source, position)
        if not match:
            raise ValueError("Malformed Steam metadata")
        token = match.group()
        position = match.end()
        if not token.isspace() and not token.startswith("//"):
            tokens.append(token)
    position = 0

    def value(token):
        return re.sub(r'\\(["\\])', r'\1', token[1:-1]) if token.startswith('"') else token

    def section(nested=False, depth=0):
        nonlocal position
        if depth > 32:
            raise ValueError("Steam metadata is too deeply nested")
        result = {}
        while position < len(tokens):
            key = tokens[position]
            position += 1
            if key == "}" and nested:
                return result
            if key in {"{", "}"} or position == len(tokens):
                raise ValueError("Malformed Steam metadata")
            item = tokens[position]
            position += 1
            if item == "}":
                raise ValueError("Missing Steam metadata value")
            result[value(key).lower()] = section(True, depth + 1) if item == "{" else value(item)
        if nested:
            raise ValueError("Unclosed Steam metadata section")
        return result

    return section()


def read_vdf(path):
    try:
        stat = path.stat()
        return parse_vdf(path, stat.st_mtime_ns, stat.st_size)
    except (OSError, ValueError):
        return {}


def steam_libraries():
    home = Path.home()
    locations = [Path(os.environ.get("XDG_DATA_HOME", home / ".local/share")) / "Steam",
                 home / ".local/share/Steam", home / ".steam/steam", home / ".steam/root",
                 home / ".var/app/com.valvesoftware.Steam/data/Steam"]
    libraries = dict.fromkeys(path.resolve() for path in locations)
    for steam in list(libraries):
        for metadata in (steam / "steamapps/libraryfolders.vdf", steam / "config/libraryfolders.vdf"):
            entries = read_vdf(metadata).get("libraryfolders", {})
            if not isinstance(entries, dict):
                continue
            for index, entry in entries.items():
                if not index.isdigit():
                    continue
                path = entry.get("path") if isinstance(entry, dict) else entry
                if isinstance(path, str) and Path(path).is_absolute():
                    libraries[Path(path).resolve()] = None
    return list(libraries)


def steam_assets(libraries):
    for library in libraries:
        manifest = read_vdf(library / "steamapps/appmanifest_431960.acf").get("appstate", {})
        install = manifest.get("installdir") if isinstance(manifest, dict) else None
        try:
            common = (library / "steamapps/common").resolve()
            assets = project_file(common, install, required=False) / "assets"
            if assets.is_dir():
                return assets
        except (OSError, ValueError):
            continue
    return None


def project_file(root, value, required=True):
    """Metadata is untrusted: reject absolute paths, parent escapes and escaping symlinks."""
    if not isinstance(value, str) or not value or Path(value).is_absolute():
        raise ValueError("Project asset must be a relative path")
    path = (root / value).resolve()
    if not path.is_relative_to(root) or (required and not path.is_file()):
        raise ValueError(f"Missing or out-of-project asset: {value}")
    return path


def scene_resolution(path):
    """Read the authored canvas from loose JSON or a bounded PKG directory entry."""
    limit = 1024 * 1024
    if path.suffix.lower() == ".json":
        if path.stat().st_size > limit:
            raise ValueError("Scene metadata exceeds 1 MiB")
        scene = json.loads(path.read_text())
    else:
        with path.open("rb") as source:
            def integer():
                data = source.read(4)
                if len(data) != 4:
                    raise ValueError("Truncated scene package")
                return struct.unpack("<i", data)[0]

            def string():
                size = integer()
                if not 0 <= size <= 4096:
                    raise ValueError("Invalid package string")
                data = source.read(size)
                if len(data) != size:
                    raise ValueError("Truncated package string")
                return data.decode("utf-8")

            if not string().startswith("PKGV"):
                raise ValueError("Unknown scene package")
            count = integer()
            if not 0 <= count <= 100000:
                raise ValueError("Invalid package entry count")
            entry = None
            expected = path.with_suffix(".json").name
            for _ in range(count):
                name, offset, size = string(), integer(), integer()
                if source.tell() > 8 * limit:
                    raise ValueError("Package directory exceeds 8 MiB")
                if name == expected or (entry is None and name == "scene.json"):
                    entry = offset, size
            if entry is None:
                return None
            offset, size = entry
            start = source.tell() + offset
            if offset < 0 or not 0 < size <= limit or start + size > path.stat().st_size:
                raise ValueError("Invalid scene metadata extent")
            source.seek(start)
            scene = json.loads(source.read(size))
    general = scene.get("general") if isinstance(scene, dict) else None
    projection = general.get("orthogonalprojection") if isinstance(general, dict) else None
    return [projection.get("width"), projection.get("height")] if isinstance(projection, dict) else None


class Provider:
    id = "wallpaper-engine"
    label = "Wallpaper Engine"

    def __init__(self, settings):
        self.settings = settings

    @property
    def roots(self):
        paths = self.settings.get("workshopPaths")
        if paths:
            return list(dict.fromkeys(Path(p).expanduser().resolve() for p in paths))
        return [library / "steamapps/workshop/content/431960" for library in steam_libraries()]

    @property
    def assets(self):
        path = self.settings.get("assetsPath")
        return Path(path).expanduser().resolve() if path else steam_assets(steam_libraries())

    def resolve(self, path):
        path = Path(path)
        candidate = path / "project.json" if path.is_dir() else path
        # A project's identity is its metadata, not an individual bundled texture/video.
        if candidate.name != "project.json":
            return None
        root = candidate.parent.resolve()
        if not any(root.parent == library for library in self.roots):
            return None
        if candidate.resolve().parent != root:
            raise ValueError("Project metadata escapes its directory")
        if candidate.stat().st_size > 1024 * 1024:
            raise ValueError("Project metadata exceeds 1 MiB")
        data = json.loads(candidate.read_text())
        if not isinstance(data, dict):
            raise ValueError("Project metadata must be an object")
        kind = data.get("type")
        if not isinstance(kind, str):
            raise ValueError("Project type is missing")
        kind = kind.lower()
        if kind not in {"scene", "video", "web"}:
            raise ValueError(f"Unsupported project type: {kind}")
        if kind == "web" and not self.settings.get("enableWeb", False):
            raise ValueError("Web wallpapers are disabled in the Wallpaper Engine addon")
        media = project_file(root, data.get("file"), required=False)
        if not media.is_file():
            # Scene entrypoints normally live inside scene.pkg, not beside project.json.
            if kind == "scene" and media.suffix.lower() == ".json":
                try:
                    media = project_file(root, str(Path(data["file"]).with_suffix(".pkg")))
                except (OSError, ValueError):
                    media = project_file(root, "scene.pkg")
            else:
                raise ValueError(f"Missing project source: {data.get('file')}")
        if kind == "video" and media.suffix.lower() not in VIDEOS:
            raise ValueError("Unsupported Workshop video format")
        preview = None
        for name in [data.get("preview"), *PREVIEWS]:
            try:
                image = project_file(root, name)
                if image.suffix.lower() in IMAGES:
                    preview = str(image)
                    break
            except (OSError, ValueError):
                continue
        title = data.get("title")
        return dict(path=str(root / "project.json"), name=title if isinstance(title, str) and title.strip() else root.name,
                    origin=self.id, provider=self.id, kind=kind, video=kind == "video",
                    renderer="mpvpaper" if kind == "video" else self.id,
                    media_path=str(media), image=preview)

    def scan(self):
        result, seen = [], set()
        for library in self.roots:
            if not library.is_dir():
                continue
            for project in sorted(library.glob("*/project.json")):
                try:
                    asset = self.resolve(project)
                    if asset and asset["path"] not in seen:
                        seen.add(asset["path"])
                        result.append(asset)
                except (OSError, ValueError) as error:
                    # Disabled web projects are intentionally absent, rather than broken entries.
                    if "Web wallpapers are disabled" not in str(error):
                        print(f"Skipping {project}: {error}", file=sys.stderr)
        return result

    def resolution(self, asset):
        # Preview art and web viewports do not describe a scene's authored resolution.
        return scene_resolution(Path(asset["media_path"])) if asset["kind"] == "scene" else None

    def start(self, asset, outputs, runtime, child_setup):
        assets = self.assets
        executable = Path(self.settings["executable"])
        if assets is None or not assets.is_dir():
            raise ValueError("Wallpaper Engine assets are unavailable. Mount/install Wallpaper Engine in Steam "
                             "or configure the addon's assetsPath.")
        if not executable.is_file():
            raise ValueError(f"Wallpaper renderer is unavailable: {executable}")
        # Revalidate on launch, including the web gate, even for a restored/direct selection.
        asset = self.resolve(Path(asset["path"]))
        names = [m["name"] for m in outputs]
        command = [str(executable), "--assets-dir", str(assets), "--silent", "--fps", "30",
                   "--no-fullscreen-pause", "--layer", "bottom"]
        command += ["--screen-span", ",".join(names)] if len(names) > 1 else ["--screen-root", names[0]]
        command += ["--bg", str(Path(asset["path"]).parent), "--scaling", "fill"]
        return Renderer(command, names, runtime, child_setup)


class Renderer:
    """One owned process group; span outputs share a renderer and pause state."""

    def __init__(self, command, outputs, runtime, child_setup):
        self.paused = False
        self.log_path = runtime / f"renderer-{time.monotonic_ns()}.log"
        with self.log_path.open("w") as log:
            # LWE also mounts its working directory as assets; do not expose the config checkout.
            self.process = subprocess.Popen(command, stdin=subprocess.DEVNULL, stdout=log,
                                            stderr=subprocess.STDOUT, start_new_session=True,
                                            preexec_fn=child_setup, cwd=runtime)
        try:
            deadline = time.monotonic() + 15
            while time.monotonic() < deadline:
                if not self.alive():
                    raise ValueError(f"Wallpaper renderer exited ({self.process.returncode}); see {self.log_path}")
                # Match this process, not the preceding renderer kept visible during the handoff.
                # A fully mapped layer establishes presentation, not scene compatibility or visual correctness.
                layers = json.loads(subprocess.run(["hyprctl", "layers", "-j"], check=True,
                                    capture_output=True, text=True, timeout=2).stdout)
                if all(any(layer.get("namespace") == "linux-wallpaperengine" and layer.get("pid") == self.process.pid
                           and layer.get("alpha", 0) >= 0.99 and layer.get("w", 0) > 0 and layer.get("h", 0) > 0
                           for entries in layers.get(name, {}).get("levels", {}).values()
                           for layer in entries) for name in outputs):
                    if self.alive():
                        return
                time.sleep(0.1)
            raise ValueError(f"Wallpaper renderer did not create its desktop surfaces; see {self.log_path}")
        except BaseException:
            self.stop()
            raise

    def alive(self):
        return self.process.poll() is None

    def set_paused(self, paused):
        if self.paused != paused and self.alive():
            os.killpg(self.process.pid, signal.SIGSTOP if paused else signal.SIGCONT)
            self.paused = paused

    def stop(self):
        try:
            # SIGTERM cannot be handled while stopped, and browser children share this group.
            os.killpg(self.process.pid, signal.SIGCONT)
            os.killpg(self.process.pid, signal.SIGTERM)
            self.process.wait(timeout=3)
        except ProcessLookupError:
            pass
        except subprocess.TimeoutExpired:
            os.killpg(self.process.pid, signal.SIGKILL)
            self.process.wait(timeout=3)
        finally:
            # The parent may have exited before its remaining children.
            try:
                os.killpg(self.process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
