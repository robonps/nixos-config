{ pkgs, ... }: {

    home.packages = with pkgs; [
        gnomeExtensions.user-themes # Allow user themes
        gnomeExtensions.tray-icons-reloaded # Reload tray icons
        gnomeExtensions.clipboard-indicator # Clipboard manager
        gnomeExtensions.pop-shell # Tiling window manager extension
        # Additional extensions can be enabled as needed
        # gnomeExtensions.vitals
        # gnomeExtensions.space-bar
        # gnomeExtensions.dash-to-panel
        # gnomeExtensions.sound-output-device-chooser
    ];

    # Dconf settings for GNOME extensions
    dconf.settings = {

        "org/gnome/shell" = {
            disable-user-extensions = false; # Enable user extensions
            enabled-extensions = [
                "user-theme@gnome-shell-extensions.gcampax.github.com"
                "trayIconsReloaded@selfmade.pl"
                "clipboard-indicator@tudmotu.com"
                "drive-menu@gnome-shell-extensions.gcampax.github.com"
                # Additional extensions can be added here
                # "pop-shell@system76.com"
                # "Vitals@CoreCoding.com"
                # "space-bar@luchrioh"
                # "dash-to-panel@jderose9.github.com"
                # "sound-output-device-chooser@kgshank.net"
            ];
        };

        # Tray Icons Reloaded settings
        "org/gnome/shell/extensions/trayIconsReloaded" = {
            icons-limit = 1; # Limit the number of tray icons
        };
    };
}