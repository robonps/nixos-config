#!/usr/bin/env bash

# Check for dependencies
if ! command -v ddcutil &> /dev/null; then
    echo "ddcutil could not be found."
    exit 1
fi

if ! command -v notify-send &> /dev/null; then
    echo "notify-send (libnotify) could not be found."
    exit 1
fi

# Create a temporary directory to store the saved brightness states
CACHE_DIR="/tmp/monitor_brightness_state"
mkdir -p "$CACHE_DIR"

# 1. BUS DETECTION
buses=$(ddcutil detect | grep "I2C bus:" | grep -oP '/dev/i2c-\K[0-9]+')
bus_array=($buses)

if [ ${#bus_array[@]} -eq 0 ]; then
    notify-send "Brightness" "Error: No monitors detected" -u critical
    exit 1
fi

# 2. Get state from FIRST monitor for instant notification
first_bus=${bus_array[0]}
output=$(ddcutil getvcp 10 --bus "$first_bus")
first_current=$(echo "$output" | grep -oP 'current value =\s*\K[0-9]+')
first_max=$(echo "$output" | grep -oP 'max value =\s*\K[0-9]+')

# Fallbacks for the first monitor
[ -z "$first_max" ] && first_max=100
[ -z "$first_current" ] && first_current=50

# 3. Calculate Notification Details based on the first monitor
save_file_first="$CACHE_DIR/bus_${first_bus}"

if [ "$first_current" -gt 1 ]; then
    # Currently bright: We will dim it
    notif_val=1
    icon="weather-clear-night" # Standard icon name for dark
    text="Dimmed ($notif_val%)"
else
    # Currently dimmed: We will restore it
    if [ -f "$save_file_first" ]; then
        notif_val=$(cat "$save_file_first")
    else
        notif_val=$first_max
    fi
    icon="weather-clear"       # Standard icon name for light
    text="Restored ($notif_val%)"
fi

# 4. NOTIFICATION (Instant Feedback)
# -h string:x-canonical-private-synchronous:brightness -> Replaces existing notification so they don't stack up
# -h int:value:$notif_val -> Shows a progress bar (supported by dunst/mako/swaync)
notify-send \
    -i "$icon" \
    -h string:x-canonical-private-synchronous:brightness \
    -h int:value:"$notif_val" \
    "Brightness" "$text"

# 5. Apply to all monitors concurrently
echo "Processing monitors..."

for bus in "${bus_array[@]}"; do
    (
        save_file="$CACHE_DIR/bus_${bus}"

        # Avoid fetching the first monitor again to speed up execution
        if [ "$bus" == "$first_bus" ]; then
            current=$first_current
            max=$first_max
        else
            bus_output=$(ddcutil getvcp 10 --bus "$bus")
            current=$(echo "$bus_output" | grep -oP 'current value =\s*\K[0-9]+')
            max=$(echo "$bus_output" | grep -oP 'max value =\s*\K[0-9]+')
            [ -z "$max" ] && max=100
            [ -z "$current" ] && current=50
        fi

        # Determine target and apply
        if [ "$current" -gt 1 ]; then
            # Save the current state and set to 1
            echo "$current" > "$save_file"
            ddcutil setvcp 10 1 --bus "$bus"
        else
            # Read saved state and restore (or default to max if missing)
            if [ -f "$save_file" ]; then
                target=$(cat "$save_file")
            else
                target=$max
            fi
            ddcutil setvcp 10 "$target" --bus "$bus"
        fi
    ) & 
done

wait
echo "Done."