{pkgs, ...}: let
  toggle-birghtness = pkgs.writeShellScriptBin "toggle-brightness" (builtins.readFile ./toggle-brightness.sh);
in {
  imports = [
    ../../common/user.nix
    ../../modules/hyprland/user.nix
    ../../modules/gaming/user.nix
    ../../modules/DAW/user.nix     # Bitwig Studio and Decent Sampler for music production
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
      "desc:Philips Consumer Electronics Company PHL 241S6Q UHB1709022150, 1920x1080@60, 0x130, 1"
      "desc:ASUSTek COMPUTER INC XG27ACMES W1LMTF197027, 2560x1440@255, 1920x0, 1, bitdepth, 10"
      "desc:Philips Consumer Electronics Company PHL 241S6Q UHB1728034524, 1920x1080@60, 4480x130, 1"
    ];

    render = {
      cm_auto_hdr = 1;
    };

    cursor = {
      no_break_fs_vrr = 1;
    };

    # Bind workspaces 1-3 to specific screens so they don't jump around
    workspace = [
      # Workspace 1 -> Left Monitor
      "1, monitor:desc:Philips Consumer Electronics Company PHL 241S6Q UHB1709022150, default:true"
      
      # Workspace 2 -> Middle Monitor
      "2, monitor:desc:ASUSTek COMPUTER INC XG27ACMES W1LMTF197027, default:true"
      
      # Workspace 3 -> Right Monitor
      "3, monitor:desc:Philips Consumer Electronics Company PHL 241S6Q UHB1728034524, default:true"
    ];

    misc = {
      vrr = 2; 
    };
  };
}
