{
  pkgs,
  lib,
  config,
  ...
}: {
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      # Import the generated colors
      source = ${config.xdg.configHome}/hypr/matugen-colors.conf

      general {
        # Use the variables defined in the imported file
        col.active_border = $active_border
        col.inactive_border = $inactive_border
        border_size = 2
      }
    '';
  };

  home.pointerCursor = {
    enable = true;
    gtk.enable = true; # Applies to GTK apps (LibreWolf, File Manager)
    x11.enable = true; # Applies to X11/Steam apps
    package = pkgs.volantes-cursors;
    name = "volantes_cursors"; # The internal folder name of the theme
    size = 24; # Standard size (try 32 if you want it bigger)
  };

  home.packages = with pkgs; [
    adw-gtk3
    adwaita-icon-theme
    papirus-icon-theme

    kdePackages.breeze
    kdePackages.breeze-icons
    kdePackages.plasma-integration
    kdePackages.plasma-workspace

    glib
    gsettings-desktop-schemas
  ];

  home.sessionVariables = {
    # Force Hyprland to use the correct cursor
    XCURSOR_THEME = "volantes_cursors";
    XCURSOR_SIZE = "24";
  };

  home.sessionVariables.XDG_DATA_DIRS = "${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:$XDG_DATA_DIRS";

  gtk = {
    enable = true;
    colorScheme = "dark";

    theme = {
      name = "adw-gtk3-dark"; # Unifies GTK3 and GTK4 look
      package = pkgs.adw-gtk3;
    };

    iconTheme = {
      name = "Papirus-Dark"; # A nice, flat icon pack
      package = pkgs.papirus-icon-theme;
    };

    cursorTheme = {
      name = "volantes_cursors";
      package = pkgs.volantes-cursors;
    };

    gtk3 = {
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };

      extraCss = ''
        @import url("colors.css");
      '';
    };

    gtk4 = {
      theme = null;

      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };

      extraCss = ''
        @import url("colors.css");
      '';
    };
  };

  # Modern Gnome apps (GTK4) ignore the theme above.
  # They look at this specific dconf setting instead.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      gtk-theme = "adw-gtk3-dark";
      icon-theme = "Papirus-Dark";
      cursor-theme = "volantes_cursors";
      cursor-size = 24;
    };
  };

  # FORCE QT APPS TO LOOK LIKE GTK
  qt = {
    enable = true;

    platformTheme = {
      name = "kde";
      package = [
        pkgs.kdePackages.plasma-integration
      ];
    };

    style = {
      name = "breeze";
      package = [
        pkgs.kdePackages.breeze
      ];
    };

    kde.settings.kdeglobals = {

      General = {
        ColorScheme = "Matugen";
      };

      KDE = {
        widgetStyle = "Breeze";
      };

      Icons = {
        Theme = "Papirus-Dark";
      };
    };
  };
}
