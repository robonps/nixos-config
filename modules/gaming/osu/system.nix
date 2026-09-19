{pkgs, ...}: {
  hardware.opentabletdriver.enable = true;

  # Recommended/required for uinput access
  hardware.uinput.enable = true;
  boot.kernelModules = [ "uinput" ];
}
