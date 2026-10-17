-- Monitor names and descriptions: hyprctl monitors all
hl.monitor({
    output = "desc:ASUSTek COMPUTER INC XG27ACMES W1LMTF197027",
    mode = "2560x1440@255",
    position = "1920x0",
    scale = 1,
    bitdepth = 10,
})

-- Additional monitors, when connected:
-- hl.monitor({ output = "desc:Philips Consumer Electronics Company PHL 241S6Q UHB1709022150", mode = "1920x1080@60", position = "0x130", scale = 1 })
-- hl.monitor({ output = "desc:Philips Consumer Electronics Company PHL 241S6Q UHB1728034524", mode = "1920x1080@60", position = "4480x130", scale = 1 })

hl.config({
    render = { cm_auto_hdr = 1 },
    cursor = { no_break_fs_vrr = true },
    misc = { vrr = 2 },
})

-- Load after the shared bindings so these overrides take precedence.
hl.unbind("XF86AudioMute")
hl.unbind("XF86AudioRaiseVolume")
hl.unbind("XF86AudioLowerVolume")
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("toggle-microphone"), { locked = true })
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("toggle-brightness"))

hl.on("hyprland.start", function()
    hl.exec_cmd("openrgb-tint")
end)

-- Pin workspaces to specific screens if needed:
-- hl.workspace_rule({ workspace = "1", monitor = "desc:Philips Consumer Electronics Company PHL 241S6Q UHB1709022150", default = true })
-- hl.workspace_rule({ workspace = "2", monitor = "desc:ASUSTek COMPUTER INC XG27ACMES W1LMTF197027", default = true })
-- hl.workspace_rule({ workspace = "3", monitor = "desc:Philips Consumer Electronics Company PHL 241S6Q UHB1728034524", default = true })
