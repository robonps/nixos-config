{ config, pkgs, ... }:

{

  imports = [
    ./applications.nix
  ];

  home.username = "robert";
  home.homeDirectory = "/home/robert";



  home.stateVersion = "24.11";

}
