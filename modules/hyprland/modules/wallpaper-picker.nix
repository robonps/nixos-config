{pkgs, theme-switcher, wallpaper-manager}: let
  scan = pkgs.writeShellApplication {
    name = "wallpaper-picker-scan";
    runtimeInputs = [wallpaper-manager];
    text = ''
      exec wallpaper-manager scan
    '';
  };
  apply = pkgs.writeShellApplication {
    name = "wallpaper-picker-apply";
    runtimeInputs = [theme-switcher];
    text = ''
      exec theme-switcher "$@"
    '';
  };
  thumbnail = pkgs.writeShellApplication {
    name = "wallpaper-picker-thumbnail";
    runtimeInputs = [wallpaper-manager];
    text = ''
      exec wallpaper-manager thumbnail "$1"
    '';
  };
in pkgs.writeShellApplication {
  name = "wall-menu";
  runtimeInputs = [pkgs.quickshell pkgs.hyprland pkgs.jq pkgs.coreutils];
  text = ''
    export WALLPAPER_PICKER_SCAN="${scan}/bin/wallpaper-picker-scan"
    export WALLPAPER_PICKER_APPLY="${apply}/bin/wallpaper-picker-apply"
    export WALLPAPER_PICKER_THUMBNAIL="${thumbnail}/bin/wallpaper-picker-thumbnail"
    if [[ "''${1:-}" == --daemon ]]; then
      shift
      exec ${pkgs.quickshell}/bin/qs --daemonize --no-duplicate --path ${./wallpaper-picker.qml} "$@"
    fi
    preview=false
    if [[ "''${1:-}" == --preview ]]; then
      preview=true
      shift
    fi
    # Capture focus before the picker takes keyboard focus, without depending on
    # Quickshell's asynchronous initial Hyprland monitor state.
    active_monitor=$(hyprctl activewindow -j 2>/dev/null | jq '.monitor // -1' || printf '%s\n' '-1')
    monitor_list=$(hyprctl monitors -j 2>/dev/null || printf '%s\n' '[]')
    WALLPAPER_PICKER_MONITOR=$(jq -r --argjson active "$active_monitor" \
      '(map(select(.id == $active)) + map(select(.focused)) + .) | first | .name // ""' <<< "$monitor_list")
    export WALLPAPER_PICKER_MONITOR
    # Most opens only show the already loaded picker. Start it on demand if login
    # preloading has not happened yet, then wait briefly for its IPC registration.
    if ${pkgs.quickshell}/bin/qs ipc --path ${./wallpaper-picker.qml} call picker open \
        "$WALLPAPER_PICKER_MONITOR" "$preview" "$WALLPAPER_PICKER_APPLY" >/dev/null 2>&1; then
      exit 0
    fi
    ${pkgs.quickshell}/bin/qs --daemonize --no-duplicate --path ${./wallpaper-picker.qml} "$@"
    for _ in {1..30}; do
      if ${pkgs.quickshell}/bin/qs ipc --path ${./wallpaper-picker.qml} call picker open \
          "$WALLPAPER_PICKER_MONITOR" "$preview" "$WALLPAPER_PICKER_APPLY" >/dev/null 2>&1; then
        exit 0
      fi
      sleep 0.02
    done
    echo "Could not open the wallpaper picker" >&2
    exit 1
  '';
}
