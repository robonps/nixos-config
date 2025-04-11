{ config, pkgs, lib, ... }:

{
    imports = [
        ./hardware-configuration.nix
        ../modules/common.nix
        ../modules/nvidia.nix
        ../modules/steam.nix
    ];

    # Bootloader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.systemd-boot.configurationLimit = 5;

    # Enable CPU microcode updates and periodic filesystem trimming
    hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    services.fstrim.enable = lib.mkDefault true;

    # Set hostname
    networking.hostName = "FastBoi";

    # State version for compatibility
    system.stateVersion = "24.11";
}
