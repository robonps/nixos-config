{ pkgs, plasma-manager, defaults, ... }: let

    vars = import ../../../vars.nix { inherit defaults;};
    default = "breeze";
    currentTheme = if vars.theme == "" then default else vars.theme;
    themePath = ./themes/${currentTheme}.nix;
in {

    imports = [
        themePath
    ];

    programs.plasma = {
        enable = true;
        overrideConfig = true;

        configFile = {
        "kcminputrc"."Libinput/1739/0/Synaptics TM3276-022"."Enabled" = true;
        "kcminputrc"."Libinput/1739/0/Synaptics TM3276-022"."NaturalScroll" = true;
        "kwinrc"."Xwayland"."Scale" = 1;
        };

    };
}
