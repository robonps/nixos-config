{pkgs, ...}: {
  imports = [
    ./hyprland.nix
    ./baseSettings.nix
    ./windows.nix
    ./windowRules.nix
    ./theming.nix
    ./binds.nix
    ./exec.nix
  ];
}
