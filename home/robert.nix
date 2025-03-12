{ config, pkgs, ... }:

{
  home.username = "robert";
  home.homeDirectory = "/home/robert";

  programs.git = {
    enable = true;
    userName = "Robert";
    userEmail = "git@robonps.com";
  };

  
  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    librewolf-bin
    vesktop
    protonvpn-gui
    vscode
    protonmail-bridge
  ];

  targets.genericLinux.enable = true;
  xdg.mime.enable = true;

  home.stateVersion = "24.11";

}
