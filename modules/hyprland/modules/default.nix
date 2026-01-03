{...}: {
  imports = [
    ./wm # Hyprland
    ./waybar
    ./rofi
    ./swaync

    ./wallpaper.nix
    ./lock.nix # Hypridle and Hyprlock
    ./packages.nix
    ./misc.nix

    ./firefox.nix
    ./kitty.nix
    #./vscode.nix
  ];
}
