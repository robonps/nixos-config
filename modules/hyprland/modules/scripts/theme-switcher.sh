#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: theme-switcher <image/video/directory> [repeat|span] [all|monitor-name]" >&2
  exit 1
fi

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-picker"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$CACHE_DIR" "$CONFIG_DIR/rofi"

# Serialize rapid selections through wallpaper application and theme generation.
exec 9>"$CACHE_DIR/theme.lock"
flock 9
if ! RESULT=$(wallpaper-manager apply "$@" 2>"$CACHE_DIR/apply-error"); then
  ERROR=$(cat "$CACHE_DIR/apply-error")
  notify-send "Wallpaper failed" "$ERROR" || true
  printf '%s\n' "$ERROR" >&2
  exit 1
fi

IMAGE=$(jq -r '.image' <<< "$RESULT")
THEME_KEY=$(jq -r '.theme_key' <<< "$RESULT")
PREVIOUS_KEY=$(cat "$CACHE_DIR/themed" 2>/dev/null || true)

# Repeating/spanning or changing outputs keeps the palette for this source.
if [[ "$THEME_KEY" != "$PREVIOUS_KEY" ]]; then
  magick "${IMAGE}[0]" -auto-orient -resize 50% -blur 0x15 -resize 200% \
    -brightness-contrast -5x0 "$CONFIG_DIR/rofi/current_wallpaper.jpg"
  if ! matugen image "$IMAGE" --source-color-index 0; then
    notify-send "Wallpaper applied" "Color generation failed; the previous theme is still active." -i "$IMAGE" || true
    exit 1
  fi
  printf '%s\n' "$THEME_KEY" > "$CACHE_DIR/themed"

  pkill -USR1 kitty || true
  pywalfox update 2>/dev/null || true
  plasma-apply-colorscheme BreezeDark >/dev/null 2>&1 || true
  plasma-apply-colorscheme Matugen >/dev/null 2>&1 || true

  current=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)
  if [[ "$current" == "'prefer-dark'" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-light || true
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
  else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark || true
    gsettings set org.gnome.desktop.interface color-scheme prefer-light || true
  fi
  swaync-client -rs || true
fi

notify-send "Wallpaper Changed" "$(basename "$(jq -r '.path' <<< "$RESULT")") · $(jq -r '.layout' <<< "$RESULT")" -i "$IMAGE" || true
