{pkgs, ...}: {
  home.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "auto";
  home.sessionVariables.NIXOS_OZONE_WL = "1";

  wayland.windowManager.hyprland.settings = {
    env = [
      "NIXOS_OZONE_WL=1"
    ];
  };

  imports = [
    ./modules
  ];

  wayland.windowManager.hyprland.configType = "hyprlang";
}
