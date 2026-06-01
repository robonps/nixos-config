{ pkgs, ... }: {
  # Enable physlock for secure screen locking
#  services.physlock = {
#    enable = true;
#    lockOn.suspend = true;
#   lockOn.hibernate = true;
#  };

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
  };

  hardware.graphics.enable = true;

  programs.dconf.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true; # Required for Sway (wlroots)
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; 
  };

  fonts.packages = with pkgs; [
    cozette
    terminus_font
  ];

}