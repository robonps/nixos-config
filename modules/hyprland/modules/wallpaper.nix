{
  pkgs,
  config,
  ...
}: let
  # We create a script that takes a path to an image as an argument
  theme-switcher = pkgs.writeShellScriptBin "theme-switcher" ''
    if [ -z "$1" ]; then
      echo "Usage: theme-switcher <path/to/image>"
      exit 1
    fi

    IMAGE="$1"

    ${pkgs.swww}/bin/swww img "$IMAGE" \
      --transition-type grow \
      --transition-pos 0.8,0.2 \
      --transition-step 90 \
      --transition-fps 60


    ${pkgs.matugen}/bin/matugen image "$IMAGE"

    pkill -USR1 kitty || true

    # Reload Waybar (Not Needed anymore)
    # systemctl --user restart waybar

    # Reload Hyprland (Not Needed anymore)
    # hyprctl reload
  '';
in {
  home.packages = [theme-switcher];

  # Define the Matugen Templates
  xdg.configFile."matugen/templates/waybar.css".text = ''
    /* Pre-calculated RGBA strings for GTK compatibility */
    @define-color glass_background rgba({{colors.surface.default.red}}, {{colors.surface.default.green}}, {{colors.surface.default.blue}}, 0.6);
    @define-color active_text_color rgba({{colors.surface.default.red}}, {{colors.surface.default.green}}, {{colors.surface.default.blue}}, 1.0);

    @define-color foreground {{colors.on_surface.default.hex}};
    @define-color primary {{colors.primary.default.hex}};
    @define-color secondary {{colors.secondary.default.hex}};
    @define-color error {{colors.error.default.hex}};
  '';
  xdg.configFile."matugen/templates/hyprland.conf".text = ''
    $active_border = rgb({{colors.primary.default.hex_stripped}})
    $inactive_border = rgb({{colors.surface_container_highest.default.hex_stripped}})
  '';

  xdg.configFile."matugen/templates/kitty.conf".text = ''
    foreground {{colors.on_surface.default.hex}}
    background {{colors.surface.default.hex}}
    cursor {{colors.on_surface.default.hex}}

    # Black
    color0 {{colors.surface.default.hex}}
    color8 {{colors.surface_bright.default.hex}}

    # Red
    color1 {{colors.error.default.hex}}
    color9 {{colors.error.default.hex}}

    # Green (Mapping primary to green for a vivid look)
    color2 {{colors.primary.default.hex}}
    color10 {{colors.primary.default.hex}}
  '';

  xdg.configFile."matugen/templates/hyprlock.conf".text = ''
    # --- CLOCK (Primary) ---
    $clock_color = rgb({{colors.primary.default.hex_stripped}})

    # --- DATE (Secondary) ---
    $date_color = rgb({{colors.secondary.default.hex_stripped}})

    # --- GREETING (Tertiary) ---
    $greeting_color = rgb({{colors.tertiary.default.hex_stripped}})

    # --- PASSWORD BOX ---
    $box_bg = rgb({{colors.surface_container_highest.default.hex_stripped}})
    $input_text = rgb({{colors.on_surface.default.hex_stripped}})
    $error = rgb({{colors.error.default.hex_stripped}})
  '';

  # Configure Matugen to use these templates
  xdg.configFile."matugen/config.toml".text = ''
    [config]
    reload_apps = true

    [templates.waybar]
    input_path = "${config.xdg.configHome}/matugen/templates/waybar.css"
    output_path = "${config.xdg.cacheHome}/matugen/colors-waybar.css"

    [templates.hyprland]
    input_path = "${config.xdg.configHome}/matugen/templates/hyprland.conf"
    output_path = "${config.xdg.cacheHome}/matugen/colors-hyprland.conf"

    [templates.kitty]
    input_path = "${config.xdg.configHome}/matugen/templates/kitty.conf"
    output_path = "${config.xdg.cacheHome}/matugen/colors-kitty.conf"

    [templates.hyprlock]
    input_path = "${config.xdg.configHome}/matugen/templates/hyprlock.conf"
    output_path = "${config.xdg.configHome}/hypr/hyprlock_colors.conf"
  '';
}
