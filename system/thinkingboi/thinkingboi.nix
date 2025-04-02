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

    # Configure bootloader
    boot.loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
    };

    # Enable CPU microcode updates and periodic filesystem trimming
    hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    services.fstrim.enable = lib.mkDefault true;

    # Configure LUKS encryption
    boot.initrd.luks.devices."luks-55207d49-5277-43ee-9cdd-7c7f932e4303".device = "/dev/disk/by-uuid/55207d49-5277-43ee-9cdd-7c7f932e4303";

    # Set hostname
    networking.hostName = "ThinkingBoi";

    # State version for compatibility
    system.stateVersion = "24.11";

}
