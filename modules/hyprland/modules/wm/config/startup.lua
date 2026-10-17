-- Run once at login; reloading the config does not restart these programs.
hl.on("hyprland.start", function()
    hl.exec_cmd("pkill -9 waybar; sleep 2; systemctl --user restart waybar")
    hl.exec_cmd("wallpaper-manager daemon")
    hl.exec_cmd("wall-menu --daemon")

    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("systemctl --user restart swaync")
end)
