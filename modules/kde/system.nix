{ pkgs, ...} : {


  services.desktopManager.plasma6.enable = true;
  services.displayManager.plasma-login-manager.enable = true;

  services.power-profiles-daemon.enable = false;
  services.keyd = {
    enable = true;

    keyboards.hfd-usb-keyboard = {
      ids = [
        "05ac:024f:cee1fbb1"
      ];

      settings = {
        main = {
          volumeup = "brightnessup";
          volumedown = "brightnessdown";
        };
      };
    };
  };

  programs.kde-pim.enable = false;

}
