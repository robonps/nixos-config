{pkgs, ...}: {
  imports = [
    ../../common/user.nix
    ../../modules/hyprland/user.nix
  ];


  home.packages = with pkgs; [
    brightnessctl
    ];



  wayland.windowManager.hyprland.settings = {
    # Syntax: "NAME, RESOLUTION, POSITION, SCALE"
    #monitor = [
    #  "eDP-1, 1920x1080@60, 0x0, 1"
    #];

    input = {
      touchpad = {
          natural_scroll = true;
      };
    };

    gestures = {
      gesture = [
        "3, horizontal, workspace"
      ];
    };

    binde = [
      ", XF86MonBrightnessUp, exec, brightnessctl set +10%"
      ", XF86MonBrightnessDown, exec, brightnessctl set 10%-"
    ];
  };

    services.kanshi = {
    enable = true;
    systemdTarget = "hyprland-session.target";
    profiles = {
      # 1. Laptop Only
      undocked = {
        outputs = [
          {
            criteria = "eDP-1";
            scale= 1.0;
            mode = "1920x1080@60";
            status = "enable";
          }
        ];
        exec = [
          "hyprctl keyword workspace 1, monitor:eDP-1"
          "hyprctl keyword workspace 2, monitor:eDP-1"
          "hyprctl keyword workspace 3, monitor:eDP-1"
          "hyprctl keyword workspace 4, monitor:eDP-1"
          "hyprctl keyword workspace 5, monitor:eDP-1"
        ];
      };

      # 2. Thunderbolt Dock (3 External Monitors)
      docked = {
        outputs = [
          { criteria = "eDP-1"; status = "disable"; }
          { criteria = "Philips Consumer Electronics Company PHL 241S6Q UHB1709022150"; status = "enable"; mode = "1920x1080@60"; position = "0,0"; }
          { criteria = "Philips Consumer Electronics Company PHL 241B6Q UHB1820031107"; status = "enable"; mode = "1920x1080@60"; position = "1920,0"; }
          { criteria = "Philips Consumer Electronics Company PHL 241S6Q UHB1728034524"; status = "enable"; mode = "1920x1080@60"; position = "3840,0"; }
        ];
        exec = [
          "hyprctl keyword workspace 1, monitor:Philips Consumer Electronics Company PHL 241S6Q UHB1709022150"
          "hyprctl keyword workspace 2, monitor:Philips Consumer Electronics Company PHL 241B6Q UHB1820031107"
          "hyprctl keyword workspace 3, monitor:Philips Consumer Electronics Company PHL 241S6Q UHB1728034524"

          "hyprctl dispatch focusmonitor Philips Consumer Electronics Company PHL 241B6Q UHB1820031107"
        ];
      };

      # 3. Simple Extended (1 External Monitor)
      extended = {
        outputs = [
          { criteria = "eDP-1"; status = "enable"; position = "0,0"; }
          { criteria = "HDMI-A-1"; status = "enable"; position = "1920,0"; }
        ];
      };
    };
  };
}
