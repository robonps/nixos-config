{pkgs, ...}: {
  imports = [
    ./hyprland.nix
    ./baseSettings.nix
    ./theming.nix
    ./binds.nix
    ./exec.nix
  ];
}
