-- Matugen writes matugen-colors.lua and reloads Hyprland through its post-hook.
-- Use the colours in windows.lua until a palette has been generated.
local configHome = os.getenv("XDG_CONFIG_HOME") or (os.getenv("HOME") .. "/.config")
local colorsFile = configHome .. "/hypr/matugen-colors.lua"
local file = io.open(colorsFile, "r")
if file then
    file:close()
    require("matugen-colors")
end
