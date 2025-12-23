{ pkgs, ... }:
{
    programs.hyprland.enable = true;

    environment.sessionVariables.NIXOS_OZONE_WL = "1";


    services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
    };


    fonts.packages = with pkgs; [
        nerd-fonts.fira-code
        nerd-fonts.droid-sans-mono
    ];
}
