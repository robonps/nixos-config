{...}: {
  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      "suppress_event maximize, match:class .*"

      # Allow some windows to float
      "float on, match:class ^(org.gnome.NautilusPreviewer)$"

      # Allow Floating setting menus
      "float on, size 800 600, center on, match:class ^(floating)$"
    ];

    layerrule = [
      "blur on, ignore_alpha 0, blur_popups on, match:namespace waybar"

      "animation slide bottom, match:namespace rofi"

      "blur on, animation fade, match:namespace logout_dialog"

      "blur on, ignore_alpha 0.5, match:namespace swaync-control-center"
      "blur on, ignore_alpha 0.5, match:namespace swaync-notification-window"
    ];
  };
}
