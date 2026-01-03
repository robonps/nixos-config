{pkgs, ...}: 

let 
  
  toggle-birghtness = pkgs.writeShellScriptBin "toggle-brightness" (builtins.readFile ./toggle-brightness.sh);
  
in {
  imports = [
    ../../common/user.nix
    ../../modules/hyprland/user.nix
  ];

  home.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    XDG_SESSION_TYPE = "wayland";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
  };


  home.packages = [ toggle-birghtness ];

  wayland.windowManager.hyprland.settings = {

    bind = [
      "$mainMod SHIFT, Q, exec, toggle-brightness"
    ];
    # Syntax: "NAME, RESOLUTION, POSITION, SCALE"
    monitor = [
      "DP-1, 1920x1080@60, 0x0, 1"
      "HDMI-A-1, 1920x1080@60, 1920x0, 1"
      "DP-2, 1920x1080@60, 3840x0, 1"
    ];

    # Bind workspaces 1-3 to specific screens so they don't jump around
    workspace = [
      "1, monitor:DP-1"
      "2, monitor:HDMI-A-1"
      "3, monitor:DP-2"
    ];
  };
}
