{pkgs, ...}: {
  xdg.configFile."hypr/config" = {
    source = ./config;
    recursive = true;
  };

  wayland.windowManager.hyprland = {
    enable = true;

    # Home Manager sets up Lua's search path and loads this entry point.
    extraLuaFiles.main = ''
      require("config")
    '';

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
