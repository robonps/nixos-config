{pkgs, ...}: {
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "pkill -9 waybar; sleep 2; systemctl --user restart waybar"

      # Wallpaper
      "wallpaper-manager daemon"
      "wall-menu --daemon"

      "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
      "systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"

      # Keyring and Polkit
      "systemctl --user start hyprpolkitagent"
      "gnome-keyring-daemon --start --components=secrets"

      "systemctl --user restart swaync"
    ];
  };
}
