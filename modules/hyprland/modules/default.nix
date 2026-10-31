{...}: {
  imports = [
    ./wm # Hyprland
    ./waybar
    ./rofi
    ./swaync
    ./wlogout

    ./theming
    ./lock.nix # Hypridle and Hyprlock
    ./packages.nix
    ./screenshot.nix
    ./misc.nix

    #./vscode.nix
  ];
}
