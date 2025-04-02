{ config, pkgs, lib, ... }:

{
    imports = [
        ./hardware-configuration.nix
        ../modules/common.nix

        # Desktop Environment
        ../modules/desktop/gnome.nix
    ];

    # GRUB bootloader configuration
    boot.loader.grub = {
        enable = true;
        device = "/dev/vda";
        useOSProber = true;
    };

    # Enable CPU microcode updates and periodic filesystem trimming
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    services.fstrim.enable = lib.mkDefault true;

    # Set hostname
    networking.hostName = "FastBoi";

    # State version for compatibility
    system.stateVersion = "24.11";
}
