{ config, pkgs, plasma-manager, defaults, ... }:

let
    # Import variables and determine desktop environment path
    vars = import ../vars.nix {inherit defaults; };
    desktopEnvironmentPath = ./modules/desktop/${vars.desktopEnvironment}/${vars.desktopEnvironment}.nix;

in {
    imports = [
        # Applications
        ./applications.nix
        
        # Desktop Environment / Window Manager
        desktopEnvironmentPath 
    ];

    # User-specific settings
    home.username = "robert";
    home.homeDirectory = "/home/robert";

    # State version for compatibility
    home.stateVersion = "24.11";
}
