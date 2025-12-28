#!/usr/bin/env bash

# --- Configuration ---
WALL_DIR="$HOME/Pictures/Wallpapers"
CACHE_DIR="$HOME/.cache/rofi-wallpaper-thumbs"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"

# Create cache dir if not exists
mkdir -p "$CACHE_DIR"

# --- 1. Generate Cache ---
# We loop through wallpapers and create thumbnails if they don't exist.
# This makes Rofi instant on subsequent runs.
echo "Checking thumbnail cache..."
find -L "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) -print0 | while IFS= read -r -d $'\0' file; do
    filename=$(basename "$file")
    thumb="$CACHE_DIR/$filename"
    
    # If thumb doesn't exist, create it using ImageMagick
    # We crop to a square 1:1 aspect ratio for a clean look
    if [ ! -f "$thumb" ]; then
        magick "$file" -resize 300x300^ -gravity center -extent 300x300 "$thumb"
    fi
done

# --- Build the Menu List ---
# Function to print the list for Rofi
gen_list() {
    # The "Random" entry
    # We use the 'urgent' tag to style it red/distinct in CSS
    echo -en "  Random\0icon\x1fview-refresh\x1fmeta\x1furgent\n"

    # The Wallpaper entries
    find -L "$WALL_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | sort | while read -r file; do
        filename=$(basename "$file")
        thumb="$CACHE_DIR/$filename"
        # Pass the filename as text, and the thumbnail path as the icon
        echo -en "$filename\0icon\x1f$thumb\n"
    done
}

# --- Run Rofi ---
# We pipe the list into rofi running in dmenu mode
SELECTED=$(gen_list | rofi -dmenu -i -selected-row 1 -p "Wallpapers" -config "$ROFI_THEME")

# --- 4. Handle Selection ---
if [ ! -z "$SELECTED" ]; then
    if [[ "$SELECTED" == "  Random"* ]]; then
        # User picked Random
        echo "Picking random wallpaper..."
        theme-switcher "$WALL_DIR"
    else
        # User picked a file
        # Rofi returns the text label (filename), so we join it with the path
        FULL_PATH="${WALL_DIR}/${SELECTED}"
        echo "Setting wallpaper to $FULL_PATH"
        theme-switcher "$FULL_PATH"
    fi
fi
