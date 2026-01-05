{...}: {
  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      "suppressevent maximize, class:.*"

      # Allow some windows to float
      "float,class:^(org.gnome.NautilusPreviewer)$"

      # Allow Floating setting menus
      "float, class:^(floating)$"
      "size 800 600, class:^(floating)$"
      "center, class:^(floating)$"
    ];

    layerrule = [
      "blur, waybar"
      "ignorezero, waybar"
      "blurpopups, waybar"

      "animation slide bottom, rofi"

      "blur, logout_dialog"
      "animation fade, logout_dialog"

      # SwayNC Rules
      "blur, swaync-control-center"
      "blur, swaync-notification-window"
      "ignorezero, swaync-control-center"
      "ignorezero, swaync-notification-window"
      "ignorealpha 0.5, swaync-control-center"
      "ignorealpha 0.5, swaync-notification-window"
    ];
  };
}
