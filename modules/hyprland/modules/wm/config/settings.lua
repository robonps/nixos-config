hl.env("NIXOS_OZONE_WL", "1")

hl.config({
    input = {
        kb_layout = "us",
        kb_options = "ctrl:nocaps",
        follow_mouse = 1,
    },
    xwayland = {
        force_zero_scaling = true,
    },
})

hl.workspace_rule({ workspace = "1", persistent = true })
