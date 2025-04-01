{ config, pkgs, ... }:

{

    imports = [
        # Applications.
        ./applications.nix
        
        # Desktop Environment / Window Manager.
        ./modules/desktop/gnome/gnome.nix

        # Environments / Addons.
        #./modules/environments/study.nix
    ];

    home.username = "robert";
    home.homeDirectory = "/home/robert";


    home.stateVersion = "24.11";
}
