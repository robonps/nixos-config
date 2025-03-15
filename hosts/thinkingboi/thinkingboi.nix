{ config, pkgs, ... }:

{
  imports = [
    ./../../modules/common.nix
    ./../../modules/laptop-specific.nix
    ./hardware-configuration.nix
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  boot.initrd.luks.devices."luks-55207d49-5277-43ee-9cdd-7c7f932e4303".device = "/dev/disk/by-uuid/55207d49-5277-43ee-9cdd-7c7f932e4303";
 
  networking.hostName = "ThinkingBoi";

  system.stateVersion = "24.11";

}
