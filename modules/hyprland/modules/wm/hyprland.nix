{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    enable = true;

    settings.workspace = [
      "1, persistent:true"
    ];

    # Systemd intergration
    systemd.enable = false;
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
