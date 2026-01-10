# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware.nix
    ../../common/system.nix # Common system config.
    ../../modules/hyprland/system.nix # Desktop
  ];

  networking.hostName = "ThinkingBoi"; # Define your hostname.
  #networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";



  services.tlp = {
    enable = true;
    settings = {
      # Set the upper charge threshold for the main internal battery (BAT0)
      STOP_CHARGE_THRESH_BAT0 = 85;

      # Set the lower charge threshold (charging starts when it drops below this)
      # It's good practice to have a 5-10% difference
      START_CHARGE_THRESH_BAT0 = 80;

      # Optional: General power saving tweaks
      # TLP defaults are good, but you can override specific settings if needed:
      # CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      # CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    };
  };


  services.throttled.enable = true;
  # Ensure the msr kernel module is loaded, which is required by throttled
  boot.kernelModules = [ "msr" ];

  services.undervolt = {
    enable = true;
    
    coreOffset = -100;    # Undervolt CPU core by 100mV
    gpuOffset = -100;     # Undervolt GPU by 100mV
    uncoreOffset = -100;  # Undervolt Uncore by 100mV
  };
}
