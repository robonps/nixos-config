{ pkgs, plasma-manager, ... }: {

    imports = [
        ./themes/breeze.nix
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