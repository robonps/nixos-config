{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    enable = true;

    # Systemd intergration
    systemd.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk # Fallback for file pickers
    ];
    config.common.default = "*";
    config.hyprland.default = ["hyprland" "gtk"];
  };
}
