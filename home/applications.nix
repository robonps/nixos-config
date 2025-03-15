{ pkgs, ... }: {
  
  imports = [
    ./modules/applications/git.nix
  ];

  nixpkgs.config.allowUnfree = true;

  home.packages = with pkgs; [
    librewolf-bin
    vesktop
    protonvpn-gui
    vscode
    mission-center
    protonmail-bridge
  ];

  targets.genericLinux.enable = true;
  xdg.mime.enable = true;

}