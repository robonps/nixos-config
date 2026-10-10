{pkgs, theme-switcher}: let
  scan = pkgs.writeShellApplication {
    name = "wallpaper-picker-scan";
    runtimeInputs = [pkgs.findutils pkgs.coreutils pkgs.jq];
    text = ''
      wall_dir="$HOME/Pictures/Wallpapers"
      cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-picker"
      current=$(cat "$cache_dir/current" 2>/dev/null || true)
      colors=$(cat "$HOME/.config/rofi/colors.rasi" 2>/dev/null || true)
      if [[ -d "$wall_dir" ]]; then
        find -L "$wall_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) -print0 | sort -z
      fi | jq -Rs --arg root "$wall_dir/" --arg current "$current" --arg colors "$colors" \
        '{files: (split("\u0000") | map(select(length > 0) | {path: ., name: ltrimstr($root)})), current: $current, colors: $colors}'
    '';
  };
  apply = pkgs.writeShellApplication {
    name = "wallpaper-picker-apply";
    runtimeInputs = [pkgs.coreutils theme-switcher];
    text = ''
      cache_dir="''${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-picker"
      mkdir -p "$cache_dir"
      printf '%s\n' "$1" > "$cache_dir/current"
      exec theme-switcher "$1"
    '';
  };
in pkgs.writeShellApplication {
  name = "wall-menu";
  runtimeInputs = [pkgs.quickshell];
  text = ''
    export WALLPAPER_PICKER_SCAN="${scan}/bin/wallpaper-picker-scan"
    export WALLPAPER_PICKER_APPLY="${apply}/bin/wallpaper-picker-apply"
    if [[ "''${1:-}" == --preview ]]; then
      export WALLPAPER_PICKER_PREVIEW=1
      shift
    fi
    exec ${pkgs.quickshell}/bin/qs --no-duplicate --path ${./wallpaper-picker.qml} "$@"
  '';
}
