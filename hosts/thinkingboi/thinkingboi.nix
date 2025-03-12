{ config, pkgs, ... }:

{
  imports = [
    ./../../modules/common.nix
    ./../../modules/laptop-specific.nix
    ./hardware-configuration.nix
  ];

  boot.loader = {
    grub.enable = true;
    grub.device = "/dev/vda";
    grub.useOSProber = true;
  };

 
 
  networking.hostName = "ThinkingBoi";

  system.stateVersion = "24.11";

}
