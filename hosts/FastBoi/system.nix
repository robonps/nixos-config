# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}:

let
  allAuthorizedKeys = import ../../modules/ssh-keys.nix; # Import the list of authorized SSH keys
in
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware.nix
    ../../common/system.nix # Common system config.
    ../../modules/hyprland/system.nix # Desktop
    ../../modules/gaming/system.nix # Gaming
    ../../modules/ssh-server/system.nix # SSH server configuration
  ];

  boot.initrd ={
    availableKernelModules = [ "r8169" ];
    network = {
      ssh = {
        enable = true;
        port = 22;
        
        # Keep this absolute path: Securely bypasses the Nix store for the private key
        hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" ];
        
        authorizedKeys = allAuthorizedKeys; 
      };
    };
  };

  boot.initrd.systemd = {
    enable = true;
    users.root.shell = "/usr/bin/systemd-tty-ask-password-agent";
    network = {
      enable = true;
      networks."10-initrd-enp5s0" = {
        matchConfig.Name = "enp5s0";
        networkConfig.DHCP = "ipv4";
      };
    };
  };

  systemd.network.enable = false;

  networking.hostName = "FastBoi"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Monitor I2C for brightness control
  hardware.i2c.enable = true;
  boot.kernelModules = ["i2c-dev"];

  # Mount secondary drive at /mnt/data
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/6e5d728e-41ea-4070-8a64-51649e92c607";
    fsType = "ext4";
    options = [
      "defaults"
      "nofail"
      "noatime"
      "x-gvfs-show"
    ];
  };

  users.users.robert.extraGroups = ["i2c" "video" "render"];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd # OpenCL ICD loader
    ];
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
    vulkan-loader
    mesa                  # This provides your built-in RADV driver
    glibc
    stdenv.cc.cc.lib
  ];

  environment.systemPackages = with pkgs; [

    mesa

    ddcutil
    amdgpu_top
  ];

  hardware.amdgpu.opencl.enable = true;

  services.lact.enable = true;
  hardware.amdgpu.overdrive.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
