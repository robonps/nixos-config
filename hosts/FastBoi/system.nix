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
    #../../modules/vm/system.nix # Virtualization support
    #../../modules/sunshine/system.nix # Game streaming
    ../../modules/ai/system.nix # AI tools
    ../../modules/jonsbo-display/system.nix # AIO CPU temperature display
  ];

  boot.plymouth = {
    enable = true;
    theme = "bgrt";
  };

  # Keep the splash visible; Escape shows boot messages.
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "rd.udev.log_level=3"
    "rd.systemd.show_status=auto"
  ];

  boot.initrd = {
    verbose = false;
    availableKernelModules = [ "r8169" "amdgpu" ];
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

  # for g502 mouse
  services.ratbagd = {
    enable = true;
    # Force NixOS to compile the latest master branch with G502 X support
    package = pkgs.libratbag.overrideAttrs (oldAttrs: {
      src = pkgs.fetchFromGitHub {
        owner = "libratbag";
        repo = "libratbag";
        rev = "master";
        # This fetches the absolute latest code definitions
        sha256 = "sha256-0uRBbVI5GrXyUUvDlpa2w5djyRWMbl6rzpdOWR2TkPg=";
      };
    });
  };

  hardware.logitech.wireless.enable = true;
  programs.solaar.enable = true;
  programs.solaar.userService.enable = false;

  # The Lightspeed mouse also advertises keyboard keys, so keyd's wildcard
  # grabs it and loses high-resolution wheel events through its virtual pointer.
  services.keyd.keyboards.default.ids = [ "-046d:4099" ];


  # RGB Lights
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
  };

  # The ASRock driver ORs RGSwap with the controller's previous hardware bits.
  # Explicit true values make its Direct-mode packing independent of what a
  # previous GUI session or firmware left behind. The tint uses GRB to match.
  systemd.services.openrgb.preStart = ''
    ${pkgs.python3}/bin/python3 - <<'PY'
    import json
    from pathlib import Path

    path = Path("/var/lib/OpenRGB/OpenRGB.json")
    settings = json.loads(path.read_text()) if path.exists() else {}
    settings.setdefault("ASRock Polychrome USB", {})["RGSwap"] = dict.fromkeys([
        "RGB LED 1 Header", "RGB LED 2 Header",
        "Addressable Header 1", "Addressable Header 2",
        "Addressable Header 3/Audio", "PCH", "IO Cover", "PCB",
    ], True)
    temporary = path.with_suffix(".json.tmp")
    temporary.write_text(json.dumps(settings, indent=4) + "\n")
    temporary.replace(path)
    PY
  '';

  # The driver restores RGSwap during detection even when the controller is
  # already in Direct mode. Re-enter Direct once to clear those hardware bits;
  # otherwise every colour frame can flash. Keep the pinned software mapping.
  systemd.services.openrgb.postStart = ''
    ${pkgs.python3.withPackages (ps: [ps.openrgb-python])}/bin/python3 - <<'PY'
    import time
    from openrgb import OpenRGBClient

    for attempt in range(100):
        try:
            client = OpenRGBClient(name="Initialise motherboard Direct mode", protocol_version=3)
            break
        except OSError:
            if attempt == 99:
                raise
            time.sleep(0.1)
    try:
        matches = [device for device in client.devices if device.name == "ASRock B850M-X WiFi R2.0"]
        if len(matches) == 1:
            device = matches[0]
            colours = list(device.colors)
            device.set_mode("Direct")
            if colours:
                device.set_colors(colours)
    finally:
        client.disconnect()
    PY
  '';

  environment.etc."libratbag/logitech-g502-x-plus.device".text = ''
    [Device]
    Name=Logitech G502 X Plus
    DeviceMatch=usb:046d:c095;usb:046d:c547
    Driver=hidpp20
  '';

  environment.systemPackages = with pkgs; [

    piper

    mesa

    ddcutil
    amdgpu_top
  ];

  hardware.amdgpu.opencl.enable = true;

  services.lact.enable = true;
  hardware.amdgpu.overdrive.enable = true;

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
