# Wallpaper Engine addon

This optional provider plugs into the existing Quickshell picker and session wallpaper manager. It adds no standalone GUI, service, flake input or global overlay. Workshop-specific discovery and renderer commands live here; the shared manager owns monitor assignments, theme updates and playback policy.

Enable it in a host's Home Manager configuration:

```nix
custom.wallpaper.addons.wallpaperEngine = {
  enable = true;
  enableWeb = false;
  # Optional overrides; empty values discover these paths from Steam at runtime.
  # assetsPath = "/mnt/data/SteamLibrary/steamapps/common/wallpaper_engine/assets";
  # workshopPaths = ["/mnt/data/SteamLibrary/steamapps/workshop/content/431960"];
  # package = pkgs.linux-wallpaperengine; # Override only this addon when testing another build.
};
```

Paths refer to runtime files, so an unmounted Steam library does not block a Nix build. Native and Flatpak Steam installations are checked, including registered libraries in `libraryfolders.vdf`; Wallpaper Engine's `appmanifest_431960.acf` supplies its installation directory. Symlinked libraries are deduplicated. Discovery refreshes when metadata changes or storage returns. Explicit assets and Workshop overrides take precedence independently, including when an override is temporarily unavailable. Discovery does not download or install anything.

The selected renderer is a dependency of the enabled manager only. FastBoi enables automatic discovery; the addon is disabled by default elsewhere. On the next wallpaper apply after a rebuild, the client compares the running manager's build and provider configuration and gracefully replaces a stale manager, including the original pre-addon daemon. Replacement verifies the socket owner's UID, process arguments and desktop session, waits for cleanup, and restores saved assignments. Concurrent selections serialize this handoff. The resident picker also refreshes all helper paths when reopened, so a new login is no longer needed for these updates.

## Picker views and previews

The three views are **All**, **Wallpapers** (local media), and **Wallpaper Engine** (Workshop projects). Search and shuffle operate within the selected view. Changing views saves immediately, including when closing without applying a wallpaper. The preference survives picker restarts, logins and reboots, independently of Repeat/Span and the applied wallpaper. It lives in `$XDG_CONFIG_HOME/wallpaper-picker/preferences.json` (normally `~/.config/wallpaper-picker/preferences.json`). Disabling the addon hides the view buttons without deleting that preference.

Workshop items use the preview named in `project.json`, including video projects. The addon can fall back to conventional preview filenames. Thumbnailing and theme generation use that bundled image, with the first frame of GIF previews; they never start the scene renderer or decode Workshop videos. A project without usable artwork gets a placeholder and leaves the current palette intact. Packed scenes may declare `scene.json` even though it lives inside `scene.pkg`; no unpacking is required.

Cards display SCENE, VIDEO or WEB using the existing video badge style; ordinary local images stay untagged. Web projects remain hidden unless enabled. Matugen runs through the shared theme helper after a successful apply and uses the cached preview PNG. Repeat/Span, output selection and picker views do not change the palette key.

The selected wallpaper's source resolution appears beneath its title. Images and videos use their media dimensions, accounting for rotation; scenes use their authored canvas from loose or packed scene metadata. This lookup runs on demand without launching a renderer or extracting Workshop video frames. Unknown dimensions, including web viewports, are omitted rather than inferred from preview artwork.

## Playback and recovery

- Local media keeps using awww/mpvpaper. Workshop videos also use mpvpaper, while retaining their project identity in the picker.
- Scenes use linux-wallpaperengine, muted at 30 FPS and on the bottom layer. Repeat uses one process per monitor; Span uses one process for the selected output group.
- The renderer's working directory is the private runtime directory. LWE mounts its working directory as another asset root, so it must not inherit the configuration checkout.
- The existing manager controls grouped fullscreen, display-power and lock-screen pausing. LWE's own fullscreen policy is disabled. Owned process groups are suspended/resumed and resumed before termination.
- Cached project artwork remains underneath scene/video playback. Renderer startup errors roll back the selection; an unexpected renderer exit is reported without restarting it on every tick. Selecting it again retries.
- During a switch, the preceding renderer stays alive until the replacement's own surfaces are fully mapped. Cached previews are updated underneath the running renderer without an image transition, avoiding an enlarged preview flashing before playback. Wallpaper layers request a fade instead of the desktop's slide animation; ordinary image-to-image changes retain awww's grow transition. This does not reproduce awww's grow/wipe effects for live renderers.
- When a replacement renderer is mapped on the same monitor, wallpaper layer cleanup suppresses Hyprland's closing snapshot during the unmap event, then restores normal entry animations on the next event-loop turn. Otherwise the compositor can draw the old wallpaper's fading snapshot above the already-visible replacement, causing a brief flash after the transition. Returning to a static image keeps the outgoing renderer's normal fade.
- Missing media or a disabled provider does not block local assignments. Saved assignments with cached previews can display those previews when their provider or Steam library is unavailable.
- Web projects are omitted and direct requests rejected unless `enableWeb = true`. This is experimental: the currently locked nixpkgs package is a June snapshot with known browser limitations. Enabling the option alone does not resolve those limitations.
- Visual checks with that build: **4K SCI-FI Black Hole** renders and animates; **Blue Sky [4K]** starts but renders black. A mapped surface is not proof that a scene is compatible. These renderer limitations are separate from stale-manager/provider errors that reject every Workshop project.
- Custom properties retain upstream defaults. V2 can provide a separate Quickshell properties window; this version adds no settings-window scaffolding.

The adapter validates loose metadata paths, but it does not sandbox or repair the native renderer's asset parsers. Surface creation checks startup; visual correctness is checked separately.

## Provider boundary and verification

The Nix wrapper supplies a manifest of explicit module paths and settings. Providers implement `Provider(settings)` with `id`, `label`, `scan()`, `resolve(path)` and `start(asset, outputs, runtime, child_setup)`, and may supply `resolution(asset)` for non-video sources. Asset records retain `path` as the picker identity and describe `origin`, `renderer`, `media_path` and optional `image`. A native renderer handle supplies `alive()`, `set_paused(bool)` and `stop()`. Library files are never loaded as Python modules.

Existing manager commands remain available. Useful inspection commands:

```sh
wallpaper-manager scan
wallpaper-manager status # Ensure the current build is running; inspect protocol/generation.
wallpaper-manager view wallpaper-engine
wallpaper-manager view local
wallpaper-manager view all
```

The picker's `picker` IPC target exposes `view <id>` and includes `view`, `savedView`, `views` and `savingView` in `status`. Applying a project accepts its directory or `project.json` through the existing `apply` command. Errors are reported in the picker and `$XDG_CACHE_HOME/wallpaper-picker/manager.log`; per-renderer startup logs live in the session's private `$XDG_RUNTIME_DIR/wallpaper-*/` directory.

Source resolutions are cached under `$XDG_CACHE_HOME/wallpaper-picker/resolutions/`, survive picker restarts, and refresh when the source or project metadata changes. Unknown dimensions are retried after five minutes. Picker scans reuse cached dimensions without launching ImageMagick or FFprobe. After scanning, background maintenance runs at most once a day and removes generated resolutions, thumbnails, frames, previews and crops unused for 30 days. Saved assignments, their fallback previews, picker preferences, logs and source wallpapers are preserved.

## Future maintenance: Python and Rust

Keep the current Python manager, Bash theme helper and Quickshell/QML interface for now. As the manager grows, split its state, IPC and renderer lifecycle code into smaller Python modules. The theme helper mostly coordinates external tools; rewriting it alone would not accelerate Matugen, ImageMagick or the wallpaper renderers.

Consider Rust if this develops into a larger, long-lived project. The manager and addon logic are the useful candidates for a shared Rust backend, with typed state and compiler checks around resource ownership. Any memory or startup-time benefit should be measured before using performance as a reason to migrate. A rewrite also introduces Cargo dependencies, compilation and regression risk.

If a migration becomes worthwhile, preserve the existing CLI/IPC contracts, saved assignments, picker preferences and optional addon boundary; retain QML for the interface. This is a future consideration, not a scheduled rewrite, and would not fix compatibility problems inside linux-wallpaperengine itself.
