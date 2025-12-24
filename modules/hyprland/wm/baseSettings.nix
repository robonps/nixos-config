{pkgs, ...}: {
  wayland.windowManager.hyprland.settings = {
    "$mainMod" = "SUPER";
    "$terminal" = "kitty";
    "$menu" = "wofi --show drun";
    "$browser" = "librewolf";
    "$fileManager" = "nautilus";

    input = {
      kb_layout = "us";
      follow_mouse = 1;
    };
  };
}
