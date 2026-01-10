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
      source = ${config.xdg.cacheHome}/matugen/colors-hyprland.conf

      general {
        # Use the variables defined in the imported file
        col.active_border = $active_border
        col.inactive_border = $inactive_border
        border_size = 2
      }
    '';
  };

  home.pointerCursor = {
    gtk.enable = true; # Applies to GTK apps (LibreWolf, File Manager)
    x11.enable = true; # Applies to X11/Steam apps
    package = pkgs.volantes-cursors;
    name = "volantes_cursors"; # The internal folder name of the theme
    size = 24; # Standard size (try 32 if you want it bigger)
  };

  home.packages = with pkgs; [
    adwaita-qt
    adwaita-qt6 
  ];

  home.sessionVariables = {
    # Force Hyprland to use the correct cursor
    XCURSOR_THEME = "volantes_cursors";
    XCURSOR_SIZE = "24";

  };

  gtk = {
    enable = true;

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

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  # Modern Gnome apps (GTK4) ignore the theme above.
  # They look at this specific dconf setting instead.
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # FORCE QT APPS TO LOOK LIKE GTK
  qt = {
    enable = true;

    platformTheme.name = "adwaita-dark";
  };
}
