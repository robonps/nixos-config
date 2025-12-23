{ pkgs, ... }:
{
    wayland.windowManager.hyprland = {
        enable = true;

        # Systemd intergration
        systemd.enable = true;

        settings = {
        "$mod" = "SUPER";
        "$terminal" = "kitty";
        "$menu" = "wofi --show drun";
        

        monitor = ",preferred,auto,1";
        
        input = {
            kb_layout = "us";
            follow_mouse = 1;
        };

        bind = [
            "$mod, Q, exec, $terminal"
            "$mod, C, killactive,"
            "$mod, SPACE, exec, $menu"
        ];
        };
    };

    home.packages = with pkgs; [
        kitty
        wofi
    ];
}