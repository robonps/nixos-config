{ config, pkgs, plasma-manager, defaults, ... }:

let
    vars = import ./vars.nix {inherit defaults; };
    desktopEnvironmentPath = ./modules/desktop/${vars.desktopEnvironment}/${vars.desktopEnvironment}.nix;
in {

    imports = [

        # Applications.
        ./applications.nix
        
        # Desktop Environment / Window Manager.
        desktopEnvironmentPath 
    ];

    home.username = "robert";
    home.homeDirectory = "/home/robert";


    home.stateVersion = "24.11";
}
