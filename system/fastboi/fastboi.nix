{ config, pkgs, lib, ... }:

{
    imports = [
        ./hardware-configuration.nix

        ../modules/common.nix

        # Desktop Environment
        ../modules/desktop/gnome.nix
    ];

    boot.loader.grub = {
        enable = true;
        device = "/dev/vda";
        useOSProber = true;
    };

    
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    services.fstrim.enable = lib.mkDefault true;

    
    networking.hostName = "FastBoi";

    system.stateVersion = "24.11";

}
