-- https://wiki.hypr.land/Configuring/Basics/Window-Rules/
hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "nautilus-preview",
    match = { class = "^org[.]gnome[.]NautilusPreviewer$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "satty",
    match = { class = "^com[.]gabm[.]satty$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "floating-settings",
    match = { class = "^floating$" },
    float = true,
    size = { 800, 600 },
    center = true,
})

hl.window_rule({
    name = "steam-main-window",
    match = { class = "^steam$", initial_title = "^Steam$", float = true },
    tile = true,
})

hl.window_rule({
    name = "kiri",
    match = { class = "^io[.]github[.]kiri[.]desktop$" },
    float = true,
    size = { 800, 680 },
    border_size = 0,
    rounding = 0,
    no_blur = true,
    no_shadow = true,
})

-- LibreWolf sets the extension title after opening the window.
hl.on("window.title", function(w)
    if w.class == "librewolf" and not w.floating
        and w.title:find("Extension: (Bitwarden Password Manager) - Bitwarden", 1, true) == 1 then
        hl.dispatch(hl.dsp.window.float({ action = "enable", window = w }))
        hl.dispatch(hl.dsp.window.center({ window = w }))
    end
end)

-- Wallpaper renderers should crossfade over the preceding wallpaper instead of sliding into view.
hl.layer_rule({
    name = "wallpaper-renderers",
    match = { namespace = "^(awww-daemon|mpvpaper|linux-wallpaperengine)$" },
    animation = "fade",
})

-- Hyprland draws closing-layer snapshots above live layers. Suppress that snapshot
-- during unmap so a retired wallpaper cannot flash over its fully loaded replacement.
local wallpaperNoExitAnimation = hl.layer_rule({
    name = "wallpaper-no-exit-animation",
    enabled = false,
    match = { namespace = "^(awww-daemon|mpvpaper|linux-wallpaperengine)$" },
    no_anim = true,
})
local wallpaperExitGeneration = 0
hl.on("layer.closed", function(layer)
    if layer.namespace ~= "awww-daemon" and layer.namespace ~= "mpvpaper"
        and layer.namespace ~= "linux-wallpaperengine" then
        return
    end
    if not layer.monitor then return end
    local replacementReady = false
    for _, other in ipairs(hl.get_layers({ monitor = layer.monitor })) do
        if other ~= layer and other.mapped
            and (other.namespace == "mpvpaper" or other.namespace == "linux-wallpaperengine") then
            replacementReady = true
            break
        end
    end
    -- Returning to a static image still uses the outgoing renderer's normal fade.
    if not replacementReady then return end
    -- This event runs before Hyprland takes the closing snapshot. Apply synchronously,
    -- then restore normal entry animations on the next event-loop turn.
    wallpaperNoExitAnimation:set_enabled(true)
    wallpaperExitGeneration = wallpaperExitGeneration + 1
    local generation = wallpaperExitGeneration
    hl.timer(function()
        if generation == wallpaperExitGeneration then
            wallpaperNoExitAnimation:set_enabled(false)
        end
    end, { timeout = 1, type = "oneshot" })
end)

hl.layer_rule({
    name = "waybar",
    match = { namespace = "waybar" },
    blur = true,
    ignore_alpha = 0,
    blur_popups = true,
})

hl.layer_rule({
    name = "rofi",
    match = { namespace = "rofi" },
    animation = "slide bottom",
})

hl.layer_rule({
    name = "wallpaper-picker",
    match = { namespace = "wallpaper-picker" },
    animation = "slide bottom",
})

hl.layer_rule({
    name = "logout-dialog",
    match = { namespace = "logout_dialog" },
    blur = true,
    animation = "fade",
})

hl.layer_rule({
    name = "swaync-control-center",
    match = { namespace = "swaync-control-center" },
    blur = true,
    ignore_alpha = 0.5,
    animation = "slide right",
})

hl.layer_rule({
    name = "swaync-notifications",
    match = { namespace = "swaync-notification-window" },
    blur = true,
    ignore_alpha = 0.5,
    animation = "slide right",
})
