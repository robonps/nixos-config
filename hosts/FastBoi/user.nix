{pkgs, ...}: {
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

  wayland.windowManager.hyprland.settings = {
    # Syntax: "NAME, RESOLUTION, POSITION, SCALE"
    monitor = [
      # 1. LEFT: DP-1 (Starts at 0)
      "DP-1, 1920x1080@60, 0x0, 1"

      # 2. CENTER: HDMI-A-1 (Starts after DP-1)
      "HDMI-A-1, 1920x1080@60, 1920x0, 1"

      # 3. RIGHT: DP-2 (Starts after HDMI)
      "DP-2, 1920x1080@60, 3840x0, 1"
    ];

    # Optional: Bind workspaces 1-3 to specific screens so they don't jump around
    workspace = [
      "1, monitor:HDMI-A-1" # Workspace 1 on Left
      "2, monitor:DP-1" # Workspace 2 on Center
      "3, monitor:DP-2" # Workspace 3 on Right
    ];
  };
}
