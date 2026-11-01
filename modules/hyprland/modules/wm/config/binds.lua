-- https://wiki.hypr.land/Configuring/Basics/Binds/
local mainMod = "SUPER"
local terminal = "kitty"
local menu = "rofi -show drun -config launcher"
local browser = "librewolf"
local fileManager = "nautilus -w"
local floatScale = 0.40

local function toggleFloating()
    local window = hl.get_active_window()
    if not window or not window.monitor then return end

    local fullscreen = window.fullscreen ~= 0 or window.fullscreen_client ~= 0
    if window.floating and not fullscreen then
        hl.dispatch(hl.dsp.window.float({ window = window, action = "disable" }))
        return
    end

    local monitor = window.monitor
    -- mode reports logical dimensions, with monitor rotation and scaling applied.
    local screen = monitor.mode
    local width = math.max(1, math.floor(screen.width * floatScale))
    local height = math.max(1, math.floor(screen.height * floatScale))

    if fullscreen then
        hl.dispatch(hl.dsp.window.fullscreen_state({
            window = window, internal = 0, client = 0, action = "set",
        }))
    end
    hl.dispatch(hl.dsp.window.float({ window = window, action = "enable" }))
    hl.dispatch(hl.dsp.window.resize({ window = window, x = width, y = height }))
    local size = window.size
    hl.dispatch(hl.dsp.window.move({
        window = window,
        x = math.floor(monitor.x + (screen.width - size.x) / 2),
        y = math.floor(monitor.y + (screen.height - size.y) / 2),
    }))
end

hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("wall-menu"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("theme-switcher ~/Pictures/Wallpapers"))

hl.bind(mainMod .. " + equal", hl.dsp.exit())
hl.bind(mainMod .. " + Space", toggleFloating)
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + O", hl.dsp.layout("togglesplit"), { description = "Toggle split" })

-- Move focus and windows.
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))

-- Workspaces 1-10; workspace 10 uses the 0 key, as in the official example.
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + comma", hl.dsp.focus({ workspace = "m-1" }))
hl.bind(mainMod .. " + period", hl.dsp.focus({ workspace = "m+1" }))
hl.bind(mainMod .. " + Tab", hl.dsp.focus({ workspace = "previous" }))
hl.bind(mainMod .. " + T", hl.dsp.focus({ workspace = "emptym" }))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.window.move({ workspace = "emptym" }))
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

hl.bind(mainMod .. " + escape", hl.dsp.exec_cmd("loginctl lock-session"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("systemctl --user restart waybar"))
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("swaync-client -t -sw"))
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("wlogout -b 5"))

hl.bind("Print", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | satty --filename -]]))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd([[grim -g "$(slurp)" - | satty --filename -]]))

-- Holding these keys repeats the action.
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"), { repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"), { repeating = true })

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- These media keys also work while the session is locked.
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
