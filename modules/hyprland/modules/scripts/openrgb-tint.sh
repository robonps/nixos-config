#!/usr/bin/env bash
set -euo pipefail

SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/openrgb/matugen.json"
PALETTE="${XDG_CACHE_HOME:-$HOME/.cache}/wal/colors.json"
ACTION=${1:-apply}
case "$ACTION" in
  apply|--off|--restore) ;;
  *) echo "Usage: openrgb-tint [--off|--restore]" >&2; exit 1 ;;
esac

# Other hosts have no RGB settings; a first login may have no palette yet.
[[ -f "$SETTINGS" ]] || exit 0
[[ -f "$PALETTE" || "$ACTION" != apply ]] || exit 0

DEVICE=$(jq -er '.device | select(type == "string" and length > 0)' "$SETTINGS")
INTENSITY=$(jq -er '.intensity | select(type == "number" and . >= 0 and . <= 100 and . == floor)' "$SETTINGS")
SATURATION=$(jq -er '(.saturation // 100) | select(type == "number" and . >= 0 and . <= 200 and . == floor)' "$SETTINGS")
TRANSITION_MS=$(jq -er '(.transition_ms // 800) | select(type == "number" and . >= 0 and . <= 5000 and . == floor)' "$SETTINGS")
CHANNEL_ORDER=$(jq -er '(.channel_order // "RGB") | select(. == "RGB" or . == "RBG" or . == "GRB" or . == "GBR" or . == "BRG" or . == "BGR")' "$SETTINGS")
# The existing Matugen pywal template maps primary to color2.
COLOR="#000000"
if [[ -f "$PALETTE" && "$ACTION" != --off ]]; then
  COLOR=$(jq -er '.colors.color2 | select(type == "string")' "$PALETTE")
fi
COLOR=${COLOR#\#}
if [[ ! "$COLOR" =~ ^[[:xdigit:]]{6}$ ]]; then
  echo "Invalid Matugen primary colour: $COLOR" >&2
  exit 1
fi

CHANNELS=("$((16#${COLOR:0:2}))" "$((16#${COLOR:2:2}))" "$((16#${COLOR:4:2}))")
MAX=0
for CHANNEL in "${CHANNELS[@]}"; do
  if (( CHANNEL > MAX )); then MAX=$CHANNEL; fi
done
# Increase distance from the brightest channel, preserving hue until clipping.
for INDEX in "${!CHANNELS[@]}"; do
  CHANNEL=$((MAX - (MAX - CHANNELS[INDEX]) * SATURATION / 100))
  if (( CHANNEL < 0 )); then CHANNEL=0; fi
  CHANNELS[INDEX]=$((CHANNEL * INTENSITY / 100))
done
printf -v TINT '%02X%02X%02X' "${CHANNELS[@]}"

# One SDK connection per fade. Keep Direct mode afterward: switching back to
# Static would reset the controller and cause another flash on the next change.
exec timeout 25s python3 - "$DEVICE" "$TINT" "$TRANSITION_MS" "$ACTION" "$CHANNEL_ORDER" <<'PY'
import fcntl
import math
import os
from pathlib import Path
import sys
import time

from openrgb import OpenRGBClient
from openrgb.utils import RGBColor


def apply_tint():
    name, tint, milliseconds, action, channel_order = sys.argv[1:]
    channels = dict(zip("RGB", (int(tint[i:i + 2], 16) for i in (0, 2, 4))))
    # Compensate for the controller's Direct-mode wiring before interpolating
    # from the server's existing values, which are already in hardware order.
    target = RGBColor(*(channels[channel] for channel in channel_order))
    duration = int(milliseconds) / 1000
    cache = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "openrgb"
    cache.mkdir(parents=True, exist_ok=True)
    # Serialize login and wallpaper updates, including separate SDK clients.
    with (cache / "tint.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        # Keep blackout state for this login only. Wallpaper updates still read
        # the latest palette, but cannot relight the motherboard while dimmed.
        runtime = Path(os.environ.get("XDG_RUNTIME_DIR", f"/tmp/openrgb-tint-{os.getuid()}"))
        runtime.mkdir(mode=0o700, parents=True, exist_ok=True)
        dimmed = runtime / "openrgb-tint.dimmed"
        if action == "--off":
            dimmed.touch()
        elif action == "--restore":
            dimmed.unlink(missing_ok=True)
        if dimmed.exists():
            target = RGBColor(0, 0, 0)
        # Protocol 4 queries plugins during startup. A headless OpenRGB server
        # does not answer that request, causing a 10-second SDK timeout.
        # Protocol 3 supports our colour/mode operations without that query.
        client = OpenRGBClient(name="Matugen motherboard tint", protocol_version=3)
        try:
            matches = [device for device in client.devices if device.name == name]
            if len(matches) != 1:
                raise ValueError(f"Expected one OpenRGB device named {name!r}; found {len(matches)}")
            device = matches[0]
            if not device.colors:
                raise ValueError(f"No LEDs configured on {name!r}")
            original = list(device.colors)
            if all(color == target for color in original):
                return
            if device.modes[device.active_mode].name != "Direct":
                device.set_mode("Direct")
            steps = max(1, math.ceil(duration * 20))
            started = time.monotonic()
            previous = original
            for step in range(1, steps + 1):
                progress = step / steps
                weight = progress * progress * (3 - 2 * progress)
                colours = [RGBColor(*(round(getattr(colour, channel) +
                                           (getattr(target, channel) - getattr(colour, channel)) * weight)
                                      for channel in ("red", "green", "blue")))
                           for colour in original]
                time.sleep(max(0, started + duration * progress - time.monotonic()))
                if colours != previous:
                    device.set_colors(colours, fast=True)
                    previous = colours
            # Confirm the server processed the final frame before disconnecting.
            device.update()
        finally:
            client.disconnect()


try:
    apply_tint()
except (OSError, ValueError, TimeoutError) as error:
    print(f"OpenRGB tint failed: {error}", file=sys.stderr)
    sys.exit(1)
PY
