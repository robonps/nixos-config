{ pkgs, plasma-manager, defaults, ... }: let

    # Import variables and set default theme
    vars = import ../../../../vars.nix { inherit defaults;};
    default = "breeze";
    currentTheme = if vars.theme == "" then default else vars.theme;
    themePath = ./themes/${currentTheme}.nix;

in {
    # Import theme-specific configurations
    imports = [
        themePath
    ];

    programs.plasma = {
        enable = true; # Enable KDE Plasma
        overrideConfig = true; # Allow overriding default configurations

        # Custom Plasma configuration
        configFile = {
            "kcminputrc"."Libinput/1739/0/Synaptics TM3276-022"."Enabled" = true;
            "kcminputrc"."Libinput/1739/0/Synaptics TM3276-022"."NaturalScroll" = true;
            "kwinrc"."Xwayland"."Scale" = 1;
        };
    };
}
