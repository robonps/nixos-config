#!/usr/bin/env bash

# Function to fetch weather
get_weather() {
    # Set a timeout so it doesn't hang forever
    bar_data=$(curl -s --max-time 15 "wttr.in/?format=%C|%t")
}

# --- RETRY LOGIC ---
# Try up to 2 times
MAX_RETRIES=2
count=0
success=false

while [ $count -lt $MAX_RETRIES ]; do
    get_weather
    
    # Validation: Check if response contains the "|" separator we asked for
    # If valid, fetch tooltip and break the loop
    if [[ "$bar_data" == *"|"* ]]; then
        # Fetch tooltip only if the main data succeeded
        tooltip_data=$(curl -s --max-time 15 "wttr.in/?0T")
        success=true
        break
    fi
    
    # If failed, wait 1 second and try again
    count=$((count + 1))
    sleep 1
done

# --- FAIL SAFE ---
# If still no success after retries, output "Unavailable" JSON and exit
if [ "$success" = false ]; then
    echo "{\"text\": \" N/A\", \"tooltip\": \"Weather service unavailable (Connection timed out)\"}"
    exit 0
fi

# --- PARSING (Original Logic) ---
condition=$(echo "$bar_data" | cut -d'|' -f1)
temp=$(echo "$bar_data" | cut -d'|' -f2)
temp_clean=$(echo "$temp" | sed 's/+//')

# Icon Mapping
case "$condition" in
    "Clear" | "Sunny")
        icon="󰖙"  # nf-md-weather_sunny
        ;;
    "Partly cloudy" | "Partly Cloudy")
        icon="󰖕"  # nf-md-weather_partly_cloudy
        ;;
    "Cloudy")
        icon="󰖐"  # nf-md-weather_cloudy
        ;;
    "Overcast")
        icon="󰖐"  # nf-md-weather_cloudy
        ;;
    "Mist" | "Fog" | "Freezing Fog")
        icon="󰖑"  # nf-md-weather_fog
        ;;
    "Rain" | "Light Rain" | "Light rain" | "Drizzle" | "Patchy rain possible")
        icon="󰖗"  # nf-md-weather_rainy
        ;;
    "Heavy Rain" | "Heavy rain" | "Showers")
        icon="󰖖"  # nf-md-weather_pouring
        ;;
    "Snow" | "Light Snow" | "Light snow" | "Patchy snow possible")
        icon="󰖘"  # nf-md-weather_snowy
        ;;
    "Heavy Snow" | "Blizzard" | "Blowing snow")
        icon="󰼶"  # nf-md-weather_snowy_heavy
        ;;
    "Thunderstorm" | "Thundery outbreaks possible")
        icon="󰖓"  # nf-md-weather_lightning
        ;;
    "Hail" | "Ice pellets")
        icon="󰖒"  # nf-md-weather_hail
        ;;
    *)
        icon="󰖝"  # nf-md-weather_windy (Default)
        ;;
esac

# ESCAPE THE TOOLTIP FOR JSON
tooltip_escaped=$(echo "$tooltip_data" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

# Output valid JSON
echo "{\"text\": \"$icon $temp_clean\", \"tooltip\": \"$tooltip_escaped\"}"