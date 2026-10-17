-- https://wiki.hypr.land/Configuring/Basics/Variables/
hl.config({
    general = {
        gaps_in = 5,
        gaps_out = 10,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        layout = "dwindle",
    },
    dwindle = {
        preserve_split = true,
    },
    decoration = {
        rounding = 10,
        active_opacity = 1,
        inactive_opacity = 1,
        blur = {
            enabled = true,
            size = 8,
            passes = 3,
            new_optimizations = true,
            ignore_opacity = true,
            xray = false,
            noise = 0.05,
        },
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
    },
    animations = {
        enabled = true,
    },
})

-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("jelly", { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.1 } } })
hl.curve("elastic", { type = "bezier", points = { { 0.36, 1.63 }, { 0.65, 1 } } })
hl.curve("gentle", { type = "bezier", points = { { 0.1, 1.1 }, { 0.1, 1.03 } } })
hl.curve("panel", { type = "bezier", points = { { 0.2, 1.35 }, { 0.3, 1 } } })

hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "elastic", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 6, bezier = "jelly", style = "popin 80%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "gentle", style = "slide" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3.5, bezier = "panel", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 3, bezier = "default", style = "slide" })
hl.animation({ leaf = "border", enabled = true, speed = 1, bezier = "jelly" })
hl.animation({ leaf = "fade", enabled = true, speed = 4, bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "gentle" })
