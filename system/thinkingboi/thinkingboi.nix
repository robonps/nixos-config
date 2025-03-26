{ config, pkgs, lib, ... }:

{
    imports = [
        ./hardware-configuration.nix
        ./power.nix

        ../modules/common.nix
        ../modules/laptop-specific.nix

        # Desktop Environment
        ../modules/desktop/gnome.nix
    ];

    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    services.fstrim.enable = lib.mkDefault true;

    boot.initrd.luks.devices."luks-55207d49-5277-43ee-9cdd-7c7f932e4303".device = "/dev/disk/by-uuid/55207d49-5277-43ee-9cdd-7c7f932e4303";
    
    networking.hostName = "ThinkingBoi";

    system.stateVersion = "24.11";

}
