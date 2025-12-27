{...}: {
  wayland.windowManager.hyprland.settings = {
    gaps_in = 5;
    gaps_out = 10;
    border_size = 2;

    "col.active_border" = "rgba(33ccffee) rgba(00ff99ee) 45deg";
    "col.inactive_border" = "rgba(595959aa)";

    layout = "dwindle";
    preserve_split = true;
    decoration = {
      rounding = 10;

      active_opacity = 0.95;
      inactive_opacity = 0.90;

      blur = {
        enabled = true;
        size = 6;
        passes = 3;
        new_optimizations = true;
        ignore_opacity = true;
        xray = false;
      };

      shadow = {
        enabled = true;
        range = 4;
        render_power = 3;
        color = "rgba(1a1a1aee)";
      };
    };

    # --- ANIMATIONS ---
    animations = {
      enabled = true;

      bezier = [
        "jelly, 0.1, 1.1, 0.1, 1.1"

        "elastic, 0.36, 1.63, 0.65, 1"

        "gentle, 0.1, 1.1, 0.1, 1.03"
      ];

      animation = [
        "windowsIn, 1, 4, elastic, popin 80%"
        "windowsOut, 1, 6, jelly, popin 80%"

        "windowsMove, 1, 4, gentle, slide"

        "border, 1, 1, jelly"
        "fade, 1, 4, default"

        "workspaces, 1, 5, gentle"
      ];
    };
  };
}
