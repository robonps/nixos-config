{ pkgs, ... }: {

    home.packages = with pkgs; [
        gnomeExtensions.user-themes
        gnomeExtensions.tray-icons-reloaded
        gnomeExtensions.clipboard-indicator
        gnomeExtensions.pop-shell
        #gnomeExtensions.vitals
        #gnomeExtensions.space-bar
        #gnomeExtensions.dash-to-panel
        #gnomeExtensions.sound-output-device-chooser
    ];


    dconf.settings = {

        "org/gnome/shell" = {
            disable-user-extensions = false;
            # `gnome-extensions list` for a list
            enabled-extensions = [
                "user-theme@gnome-shell-extensions.gcampax.github.com"
                "trayIconsReloaded@selfmade.pl"
                "clipboard-indicator@tudmotu.com"
                "drive-menu@gnome-shell-extensions.gcampax.github.com"
                #"pop-shell@system76.com"
                #"Vitals@CoreCoding.com"
                #"space-bar@luchrioh"
                #"dash-to-panel@jderose9.github.com"
                #"sound-output-device-chooser@kgshank.net"
            ];

        };

        # Vitals Settings
        #"org/gnome/shell/extensions/vitals" = {
        #    hot-sensors = ["_processor_usage_"];
        #};

        # Tray Icons Reloaded settings
        "org/gnome/shell/extensions/trayIconsReloaded" = {
            icons-limit = 1;
        };
    };
}