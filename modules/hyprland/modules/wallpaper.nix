{
  pkgs,
  config,
  ...
}: let
  # We create a script that takes a path to an image as an argument
  theme-switcher = pkgs.writeShellScriptBin "theme-switcher" (builtins.readFile ./scripts/theme-switcher.sh);
  wall-menu = pkgs.writeShellScriptBin "wall-menu" (builtins.readFile ./scripts/wall-menu.sh);
in {
  home.packages = [theme-switcher wall-menu];

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

  xdg.configFile."matugen/templates/pywal.json".text = ''
    {
      "wallpaper": "None",
      "alpha": "100",
      "special": {
          "background": "{{colors.surface.default.hex}}",
          "foreground": "{{colors.on_surface.default.hex}}",
          "cursor": "{{colors.on_surface.default.hex}}"
      },
      "colors": {
          "color0": "{{colors.surface.default.hex}}",
          "color1": "{{colors.error.default.hex}}",
          "color2": "{{colors.primary.default.hex}}",
          "color3": "{{colors.secondary.default.hex}}",
          "color4": "{{colors.on_primary.default.hex}}",
          "color5": "{{colors.primary_container.default.hex}}",
          "color6": "{{colors.secondary_container.default.hex}}",
          "color7": "{{colors.on_surface.default.hex}}",
          "color8": "{{colors.surface_bright.default.hex}}",
          "color9": "{{colors.error_container.default.hex}}",
          "color10": "{{colors.tertiary.default.hex}}",
          "color11": "{{colors.on_secondary.default.hex}}",
          "color12": "{{colors.on_tertiary.default.hex}}",
          "color13": "{{colors.on_primary_container.default.hex}}",
          "color14": "{{colors.on_secondary_container.default.hex}}",
          "color15": "{{colors.on_surface_variant.default.hex}}"
      }
    }
  '';

  xdg.configFile."matugen/templates/rofi-colors.rasi".text = ''
    * {
      /* Matugen Template for Rofi */

      /* Background: Default surface color */
      background:       {{colors.surface.default.hex}};

      /* Background Alpha: Surface color with transparency (e.g., 80% opacity)
        Note: You might need to adjust the hex opacity code (CC = 80%) depending on preference */
      background-alpha: {{colors.surface.default.hex}}CC;

      /* Foreground: Text on surface */
      foreground:       {{colors.on_surface.default.hex}};

      /* Selected: Primary color */
      selected:         {{colors.primary.default.hex}};

      /* Selected Text: Text on Primary color */
      selected-text:    {{colors.on_primary.default.hex}};

      /* Active: Secondary Container (often used for active elements not currently selected) */
      active:           {{colors.secondary_container.default.hex}};

      /* Urgent: Error color */
      urgent:           {{colors.error.default.hex}};

      /* Border: Outline color */
      border-color:     {{colors.outline.default.hex}};
    }
  '';

  # Discord/Vesktop Template
  xdg.configFile."matugen/templates/midnight-discord.css".source = ./templates/midnight-discord.css;

  xdg.configFile."matugen/templates/swaync.css".text = ''
    @define-color shadow {{colors.shadow.default.hex}};
    @define-color background {{colors.background.default.hex}};

    /* Surface Colors - From Darkest to Lightest */
    @define-color surface_dim {{colors.surface_dim.default.hex}};
    @define-color surface_container_lowest {{colors.surface_container_lowest.default.hex}};
    @define-color surface_container_low {{colors.surface_container_low.default.hex}};
    @define-color surface_container {{colors.surface_container.default.hex}};
    @define-color surface_container_high {{colors.surface_container_high.default.hex}};
    @define-color surface_container_highest {{colors.surface_container_highest.default.hex}};
    @define-color surface {{colors.surface.default.hex}};
    @define-color on_surface {{colors.on_surface.default.hex}};
    @define-color on_surface_variant {{colors.on_surface_variant.default.hex}};

    /* Accents */
    @define-color primary {{colors.primary.default.hex}};
    @define-color on_primary {{colors.on_primary.default.hex}};
    @define-color primary_container {{colors.primary_container.default.hex}};
    @define-color on_primary_container {{colors.on_primary_container.default.hex}};

    @define-color secondary {{colors.secondary.default.hex}};
    @define-color on_secondary {{colors.on_secondary.default.hex}};
    @define-color secondary_container {{colors.secondary_container.default.hex}};
    @define-color on_secondary_container {{colors.on_secondary_container.default.hex}};

    @define-color tertiary {{colors.tertiary.default.hex}};
    @define-color on_tertiary {{colors.on_tertiary.default.hex}};
    @define-color tertiary_container {{colors.tertiary_container.default.hex}};
    @define-color on_tertiary_container {{colors.on_tertiary_container.default.hex}};

    @define-color error {{colors.error.default.hex}};
    @define-color on_error {{colors.on_error.default.hex}};

    @define-color outline {{colors.outline.default.hex}};
    @define-color outline_variant {{colors.outline_variant.default.hex}};
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

    [templates.pywal]
    input_path = "${config.xdg.configHome}/matugen/templates/pywal.json"
    output_path = "${config.xdg.cacheHome}/wal/colors.json"

    [templates.vesktop]
    input_path = "${config.xdg.configHome}/matugen/templates/midnight-discord.css"
    output_path = "${config.xdg.configHome}/vesktop/themes/midnight-discord.css"

    [templates.rofi]
    input_path = "${config.xdg.configHome}/matugen/templates/rofi-colors.rasi"
    output_path = "${config.xdg.configHome}/rofi/colors.rasi"

    [templates.swaync]
    input_path = "${config.xdg.configHome}/matugen/templates/swaync.css"
    output_path = "${config.xdg.configHome}/swaync/colors.css"
  '';
}
