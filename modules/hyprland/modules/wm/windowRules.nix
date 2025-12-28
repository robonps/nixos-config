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

      "animation slide bottom, rofi"
    ];
  };
}
