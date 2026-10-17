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

-- https://wiki.hypr.land/Configuring/Basics/Layer-Rules/
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
