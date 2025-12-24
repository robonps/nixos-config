{
  pkgs,
  lib,
  ...
}: {
  home.pointerCursor = {
    gtk.enable = true; # Applies to GTK apps (LibreWolf, File Manager)
    x11.enable = true; # Applies to X11/Steam apps
    package = pkgs.volantes-cursors;
    name = "volantes_cursors"; # The internal folder name of the theme
    size = 24; # Standard size (try 32 if you want it bigger)
  };

  home.sessionVariables = {
    # Force Hyprland to use the correct cursor
    XCURSOR_THEME = "volantes_cursors";
    XCURSOR_SIZE = "24";

    # Tell Qt apps to follow the GTK theme explicitly
    QT_QPA_PLATFORMTHEME = lib.mkForce "gtk3";
    QT_QPA_PLATFORM = "wayland;xcb";
  };

  gtk = {
    enable = true;

    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome-themes-extra;
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

    # For some apps that might check this legacy path
    "org/gnome/desktop/interface" = {
      gtk-theme = "Adwaita-dark";
    };
  };

  # FORCE QT APPS TO LOOK LIKE GTK
  qt = {
    enable = true;

    # This tells Qt to use the "GTK" platform theme, which reads your GTK settings.
    platformTheme.name = "gtk";

    # We also force the specific style to "adwaita-dark"
    style = {
      name = "adwaita-dark";

      # IMPORTANT: You must install the theme package for both Qt5 and Qt6
      package = pkgs.adwaita-qt;
    };
  };
}
