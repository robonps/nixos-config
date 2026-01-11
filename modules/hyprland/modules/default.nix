{...}: {
  imports = [
    ./wm # Hyprland
    ./waybar
    ./rofi
    ./swaync
    ./wlogout

    ./wallpaper.nix
    ./lock.nix # Hypridle and Hyprlock
    ./packages.nix
    ./screenshot.nix
    ./misc.nix

    ./firefox.nix
    ./kitty.nix
    #./vscode.nix
  ];
}
