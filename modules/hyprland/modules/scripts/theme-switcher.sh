#!/usr/bin/env bash

# Check if argument is provided
if [ -z "$1" ]; then
  echo "Usage: theme-switcher <path/to/image OR path/to/directory>"
  exit 1
fi

TARGET="$1"
ROFI_IMG="$HOME/.config/rofi/current_wallpaper.jpg"

# Logic: If directory, pick random; if file, use it; else fail.
if [ -d "$TARGET" ]; then
  # Find files ending in common image extensions and shuffle to pick one
  IMAGE=$(find -L "$TARGET" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) | shuf -n 1)
  
  if [ -z "$IMAGE" ]; then
    echo "Error: No image files found in directory '$TARGET'"
    exit 1
  fi
  echo "Randomly selected: $IMAGE"

elif [ -f "$TARGET" ]; then
  IMAGE="$TARGET"
else
  echo "Error: '$TARGET' is not a valid file or directory"
  exit 1
fi

# ---- Existing Logic Below ----

# Make sure swww, matugen, and pywalfox are in home.packages
swww img "$IMAGE" \
  --transition-type grow \
  --transition-pos 0.5,0.0 \
  --transition-step 90 \
  --transition-fps 60

# We resize it down and up to blur it faster, then crop it to a square-ish ratio if needed.
magick "$IMAGE" -resize 50% -blur 0x15 -resize 200% -brightness-contrast -5x0 "$ROFI_IMG"

matugen image "$IMAGE"

pkill -USR1 kitty || true

pywalfox update 2>/dev/null || true