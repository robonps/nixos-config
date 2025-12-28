{...}: {
  imports = [
    ./wm # Hyprland
    ./waybar
    ./rofi

    ./wallpaper.nix
    ./lock.nix # Hypridle and Hyprlock
    ./packages.nix
    ./misc.nix

    ./firefox.nix
    ./kitty.nix
    #./vscode.nix
  ];
}
