{ pkgs, ... }: {
    imports = [
        ./extensions.nix
        ./themes/adwaita.nix
    ];




    dconf.settings = {

        "org/gtk/gtk4/settings/file-chooser" = {
            show-hidden = true;
        };

        "org/gnome/settings-daemon/plugins/color" = {
            night-light-enabled = true;
            night-light-schedule-from = 20.0;
            night-light-schedule-to = 6.0;
        };

        "org/gnome/desktop/interface" = {
            enable-hot-corners = false;
            show-battery-percentage = true;
        };


        # Shortcuts
        "org/gnome/settings-daemon/plugins/media-keys" = {
            home = ["<Super>e"];

            custom-keybindings = ["/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"];
        };



        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
            binding = "<Super>Return";
            command = "kgx";
            name = "Terminal";
        };

    };
}