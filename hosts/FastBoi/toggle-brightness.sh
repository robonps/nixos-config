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

# 1. BUS DETECTION
buses=$(ddcutil detect | grep "I2C bus:" | grep -oP '/dev/i2c-\K[0-9]+')
bus_array=($buses)

if [ ${#bus_array[@]} -eq 0 ]; then
    notify-send "Brightness" "Error: No monitors detected" -u critical
    exit 1
fi

# 2. Get state from FIRST monitor
first_bus=${bus_array[0]}
output=$(ddcutil getvcp 10 --bus "$first_bus")
current=$(echo "$output" | grep -oP 'current value =\s*\K[0-9]+')
max=$(echo "$output" | grep -oP 'max value =\s*\K[0-9]+')

# Fallbacks
[ -z "$max" ] && max=100
[ -z "$current" ] && current=50 # Default safe value if read fails

# 3. Calculate Target
low=1
high=$max

if [ "$current" -gt $((max / 2)) ]; then
    new=$low
    icon="weather-clear-night" # Standard icon name for dark
    text="Low ($new%)"
else
    new=$high
    icon="weather-clear"       # Standard icon name for light
    text="High ($new%)"
fi

# 4. NOTIFICATION (Instant Feedback)
# -h string:x-canonical-private-synchronous:brightness -> Replaces existing notification so they don't stack up
# -h int:value:$new -> Shows a progress bar (supported by dunst/mako/swaync)
notify-send \
    -i "$icon" \
    -h string:x-canonical-private-synchronous:brightness \
    -h int:value:"$new" \
    "Brightness" "$text"

# 5. Apply to monitors
echo "Setting brightness to $new..."

for bus in "${bus_array[@]}"; do
    (
        ddcutil setvcp 10 $new --bus "$bus"
    ) & 
    #sleep 0.3
done

wait