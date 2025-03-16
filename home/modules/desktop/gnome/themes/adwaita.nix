{ pkgs, ... }: {

    home.packages = with pkgs; [
        gruvbox-gtk-theme
    ];

    # Use `dconf watch /` to track stateful changes you are doing, then set them here.
    dconf.settings = {
        "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
        };
        
        "org/gnome/shell/extensions/user-theme" = {
            name = "Gruvbox-Dark";
        };

    };


    # GTK theming settings
    gtk = {
        enable = true;

        iconTheme = {
            name = "Papirus-Dark";
            package = pkgs.papirus-icon-theme;
        };

        theme = {
            name = "Gruvbox-Dark";
            package = pkgs.gruvbox-gtk-theme;
        };

        cursorTheme = {
            name = "volantes_cursors";
            package = pkgs.volantes-cursors;
        };

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

    home.sessionVariables.GTK_THEME = "Gruvbox-Dark";

}