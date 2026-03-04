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


  services.hardware.bolt.enable = true; # Thunderbolt support

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

  # Ensure the msr kernel module is loaded, which is required by throttled
  boot.kernelModules = [ "msr" ];
  services.throttled = {
    enable = true;
    extraConfig = ''
      [GENERAL]
      # Enable or disable the script execution
      Enabled: True
      # SYSFS path for checking if the system is running on AC power
      Sysfs_Power_Path: /sys/class/power_supply/AC*/online
      # Auto reload config on changes
      Autoreload: True

      ## Settings to apply while connected to Battery power
      [BATTERY]
      # Update the registers every this many seconds
      Update_Rate_s: 30
      # Max package power for time window #1
      PL1_Tdp_W: 29
      # Time window #1 duration
      PL1_Duration_s: 28
      # Max package power for time window #2
      PL2_Tdp_W: 44
      # Time window #2 duration
      PL2_Duration_S: 0.002
      # Max allowed temperature before throttling
      Trip_Temp_C: 85
      # Set cTDP to normal=0, down=1 or up=2 (EXPERIMENTAL)
      cTDP: 0
      # Disable BDPROCHOT (EXPERIMENTAL)
      Disable_BDPROCHOT: False

      ## Settings to apply while connected to AC power
      [AC]
      # Update the registers every this many seconds
      Update_Rate_s: 5
      # Max package power for time window #1
      PL1_Tdp_W: 44
      # Time window #1 duration
      PL1_Duration_s: 28
      # Max package power for time window #2
      PL2_Tdp_W: 44
      # Time window #2 duration
      PL2_Duration_S: 0.002
      # Max allowed temperature before throttling
      Trip_Temp_C: 95
      # Set HWP energy performance hints to 'performance' on high load (EXPERIMENTAL)
      # Uncomment only if you really want to use it
      # HWP_Mode: False
      # Set cTDP to normal=0, down=1 or up=2 (EXPERIMENTAL)
      cTDP: 0
      # Disable BDPROCHOT (EXPERIMENTAL)
      Disable_BDPROCHOT: False

      # All voltage values are expressed in mV and *MUST* be negative (i.e. undervolt)! 
      [UNDERVOLT]
      # CPU core voltage offset (mV)
      CORE: -100
      # Integrated GPU voltage offset (mV)
      GPU: -85
      # CPU cache voltage offset (mV)
      CACHE: -100
      # System Agent voltage offset (mV)
      UNCORE: -100
      # Analog I/O voltage offset (mV)
      ANALOGIO: 0
    '';
  };
}
