{pkgs, ...}: {
  wayland.windowManager.hyprland.settings = {
    "$mainMod" = "SUPER";
    "$terminal" = "kitty";
    "$menu" = "rofi -show drun -config launcher";
    "$browser" = "librewolf";
    "$fileManager" = "nautilus -w";

    input = {
      kb_layout = "us";
      follow_mouse = 1;
    };

    xwayland = {
      force_zero_scaling = true;
    };
  };
}
