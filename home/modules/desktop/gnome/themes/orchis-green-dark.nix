{ pkgs, ... }: {

    # Dconf settings for GNOME
    dconf.settings = {
        "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark"; # Use dark color scheme
        };
        
        "org/gnome/shell/extensions/user-theme" = {
            name = "Orchis-Green-Dark"; # Set the user theme to Gruvbox Dark
        };
    };

    # GTK theming settings
    gtk = {
        enable = true; # Enable GTK theming

        iconTheme = {
            name = "Papirus-Dark"; # Set icon theme
            package = pkgs.papirus-icon-theme;
        };

        theme = {
            name = "Orchis-Green-Dark"; # Set GTK theme
            package = pkgs.orchis-theme;
        };

        cursorTheme = {
            name = "graphite-dark"; # Set cursor theme
            package = pkgs.graphite-cursors;
        };

        # Additional GTK configurations
        gtk3.extraConfig = {
            Settings = ''
                gtk-application-prefer-dark-theme=1
            '';
        };

        gtk4.extraConfig = {
            Settings = ''
                gtk-application-prefer-dark-theme=1
            '';
        };
    };

    home.sessionVariables.GTK_THEME = "Orchis-Green-Dark"; # Set GTK_THEME environment variable

}