{pkgs, ...}: let
  toggle-birghtness = pkgs.writeShellScriptBin "toggle-brightness" (builtins.readFile ./toggle-brightness.sh);
in {
  imports = [
    ../../common/user.nix
    ../../modules/hyprland/user.nix
    ../../modules/gaming/user.nix
  ];

  home.sessionVariables = {
    LIBVA_DRIVER_NAME = "radeonsi";
  };

  home.packages = [
    toggle-birghtness
  ];

  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mainMod SHIFT, Q, exec, toggle-brightness"
    ];
    # Syntax: "NAME, RESOLUTION, POSITION, SCALE"
    monitor = [
      "desc:Philips Consumer Electronics Company PHL 241S6Q UHB1709022150, 1920x1080@60, 0x0, 1"
      "desc:Philips Consumer Electronics Company PHL 241B6Q UHB1820031107, 1920x1080@60, 1920x0, 1"
      "desc:Philips Consumer Electronics Company PHL 241S6Q UHB1728034524, 1920x1080@60, 3840x0, 1"
    ];

    # Bind workspaces 1-3 to specific screens so they don't jump around
    workspace = [
      # Workspace 1 -> Left Monitor
      "1, monitor:desc:Philips Consumer Electronics Company PHL 241S6Q UHB1709022150, default:true"
      
      # Workspace 2 -> Middle Monitor
      "2, monitor:desc:Philips Consumer Electronics Company PHL 241B6Q UHB1820031107, default:true"
      
      # Workspace 3 -> Right Monitor
      "3, monitor:desc:Philips Consumer Electronics Company PHL 241S6Q UHB1728034524, default:true"
    ];
  };
}
