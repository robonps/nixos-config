{ ... }:

{
  # Sunshine game-streaming host
  services.sunshine = {
    enable = true;
    autoStart = true;

    # Required for DRM/KMS capture.
    capSysAdmin = true;

    # Opens the Moonlight/Sunshine ports automatically.
    openFirewall = true;
  };

  # For remote keyboard/mouse/controller input.
  hardware.uinput.enable = true;

  users.users.robert.extraGroups = [
    "uinput"
  ];

  # DualSense/DS5 emulation uses /dev/uhid.
  services.udev.extraRules = ''
    KERNEL=="uhid", SUBSYSTEM=="misc", GROUP="uinput", MODE="0660"
  '';

  hardware.graphics.enable = true;
}