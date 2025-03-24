{ config, pkgs, ... }:

{

    imports = [
        ./applications.nix
        ./modules/desktop/gnome/gnome.nix


        ./modules/environments/study.nix
    ];

    home.username = "robert";
    home.homeDirectory = "/home/robert";


    home.stateVersion = "24.11";
}
