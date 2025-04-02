{ pkgs, ... }: {

    home.packages = with pkgs; [
        gruvbox-gtk-theme # Install Gruvbox GTK theme
    ];

    # Dconf settings for GNOME
    dconf.settings = {
        "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark"; # Use dark color scheme
        };
        
        "org/gnome/shell/extensions/user-theme" = {
            name = "Gruvbox-Dark"; # Set the user theme to Gruvbox Dark
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
            name = "Gruvbox-Dark"; # Set GTK theme
            package = pkgs.gruvbox-gtk-theme;
        };

        cursorTheme = {
            name = "volantes_cursors"; # Set cursor theme
            package = pkgs.volantes-cursors;
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

    home.sessionVariables.GTK_THEME = "Gruvbox-Dark"; # Set GTK_THEME environment variable

}