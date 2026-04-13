{pkgs, ...}: {

  imports = [
    #./vr-test.nix
  ];

  programs.steam = {
    enable = true;

    remotePlay.openFirewall = true;

    dedicatedServer.openFirewall = true;

    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud # The FPS counter overlay
    protonup-qt # GUI to download custom Proton versions (GE-Proton)
  ];


  # Udev rules for gaming controllers
  services.udev.extraRules = ''
    # Disable DualShock 4 / DualSense touchpad acting as mouse (USB)
    ATTRS{name}=="Sony Interactive Entertainment DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    
    # Disable DualShock 4 / DualSense touchpad acting as mouse (Bluetooth)
    ATTRS{name}=="DualSense Wireless Controller Touchpad", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';


  # For MC
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        main = {
        };
        speedrun = {
          # Inside this mode, R becomes F3
          r = "f3";
        };

        "meta+shift" = {
        a = "toggle(speedrun)";
      };
      };
    };
  };
}
