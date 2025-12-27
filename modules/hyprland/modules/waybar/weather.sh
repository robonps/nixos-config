#!/usr/bin/env bash

# Fetch the simple data for the BAR (Icon + Temp)
# We strictly define the format here to ensure we can parse it easily
bar_data=$(curl -s "wttr.in/?format=%C|%t")

# Fetch the complex data for the TOOLTIP (ASCII Art)
# ?0 = Weather only (no forecast days)
# T  = No colors (prevents weird symbols in the tooltip)
tooltip_data=$(curl -s "wttr.in/?0T")

# Parse the simple bar data
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
# 1. Escape backslashes first
# 2. Escape double quotes
# 3. Replace actual newlines with literal '\n' string
tooltip_escaped=$(echo "$tooltip_data" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

# Output valid JSON
echo "{\"text\": \"$icon $temp_clean\", \"tooltip\": \"$tooltip_escaped\"}"