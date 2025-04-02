{ pkgs, defaults, ... }:
let

    # Import variables and set default theme
    vars = import ../../../vars.nix { inherit defaults;};
    default = "gruvbox-dark";
    currentTheme = if vars.theme == "" then default else vars.theme;
    themePath = ./themes/${currentTheme}.nix;

in {
    # Import additional configurations
    imports = [
        ./extensions.nix
        themePath
    ];

    dconf.settings = {
        # File chooser settings
        "org/gtk/gtk4/settings/file-chooser" = {
            show-hidden = true;
        };

        # Night light settings
        "org/gnome/settings-daemon/plugins/color" = {
            night-light-enabled = true;
            night-light-schedule-from = 20.0;
            night-light-schedule-to = 6.0;
        };

        # Interface settings
        "org/gnome/desktop/interface" = {
            enable-hot-corners = false;
            show-battery-percentage = true;
            monospace-font-name = "FiraCode Nerd Font 10";
        };

        # Keyboard shortcuts
        "org/gnome/settings-daemon/plugins/media-keys" = {
            home = ["<Super>e"];
            custom-keybindings = ["/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"];
        };

        # Custom shortcut for launching terminal
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
            binding = "<Super>Return";
            command = "kgx";
            name = "Terminal";
        };
    };
}
