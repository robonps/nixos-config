{...}: {
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      "suppress_event maximize, match:class .*"

      # Allow some windows to float
      "float on, center on, match:class ^(org.gnome.NautilusPreviewer)$"
      "float on, center on, match:class ^(com.gabm.satty)$"

      # Allow Floating setting menus
      "float on, size 800 600, center on, match:class ^(floating)$"

      # Fix Steam
      "tile on, match:class ^(steam)$, match:initial_title ^(Steam)$, match:float 1"

      # Kiri
      "float on, size 800 680, border_size 0, rounding 0, no_blur on, no_shadow on, match:class ^io[.]github[.]kiri[.]desktop$"
    ];

    layerrule = [
      "blur on, ignore_alpha 0, blur_popups on, match:namespace waybar"

      "animation slide bottom, match:namespace rofi"
      "animation slide bottom, match:namespace wallpaper-picker"

      "blur on, animation fade, match:namespace logout_dialog"

      "blur on, ignore_alpha 0.5, animation slide right, match:namespace swaync-control-center"
      "blur on, ignore_alpha 0.5, match:namespace swaync-notification-window"
    ];
  };
}
