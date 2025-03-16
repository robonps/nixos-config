{ config, pkgs, ... }:

{

    imports = [
        ./applications.nix
        ./modules/desktop/kde/kde.nix
    ];

    home.username = "robert";
    home.homeDirectory = "/home/robert";


    home.stateVersion = "24.11";
}
