{ pkgs, ...} : {


  services.desktopManager.gnome.enable = true;
  services.displayManager.gdm.enable = true;

  services.power-profiles-daemon.enable = false;


  environment.gnome.excludePackages = with pkgs; [
    epiphany
    geary
    gnome-maps
    gnome-weather
    gnome-contacts
    gnome-calendar
    gnome-music
    gnome-tour
    gnome-user-docs
  ];


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

}
