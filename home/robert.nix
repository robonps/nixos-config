{ config, pkgs, ... }:

{

    imports = [
        ./applications.nix
        ./modules/desktop/gnome/gnome.nix
    ];

    home.username = "robert";
    home.homeDirectory = "/home/robert";


    home.stateVersion = "24.11";
}
