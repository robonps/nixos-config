{ config, pkgs, ... }:

let
    hostname = builtins.getEnv "HOSTNAME";

    baseModule = [
        # Base Modules.


        # Applications.
        ./applications.nix
        
        # Desktop Environment / Window Manager.
        ./modules/desktop/gnome/gnome.nix
    ];

    thinkingBoi = [
        # Environments / Addons (Currently Based on Hostname).
        ./modules/environments/study.nix
    ];

    fastBoi = [
        # Environments / Addons (Currently Based on Hostname).
        ./modules/environments/gaming.nix
    ];

{

    imports = if hostname == "ThinkingBoi" then
        baseModule ++ thinkingBoi
    else if hostname == "FastBoi" then
        baseModule ++ fastBoi
    else
        baseModule;

    home.username = "robert";
    home.homeDirectory = "/home/robert";


    home.stateVersion = "24.11";
}
