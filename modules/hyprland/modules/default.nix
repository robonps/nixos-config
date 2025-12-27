{pkgs, ...}: {
  imports = [
    ./wm # Hyprland
    ./waybar

    ./wallpaper.nix
    ./lock.nix # Hypridle and Hyprlock
    ./packages.nix
    ./kitty.nix
    ./misc.nix
  ];
}
