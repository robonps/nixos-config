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
    monitor = [
      "eDP-1, 1920x1080@60, 0x0, 1"
    ];

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
}
