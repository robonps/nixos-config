{ config, pkgs, ... }: {

  home.packages = with pkgs; [
    grim
    slurp
    satty
    wl-clipboard
  ];

  # Ensure screenshot directory exists
  systemd.user.tmpfiles.rules = [
    "d ${config.home.homeDirectory}/Pictures/Screenshots 0755 ${config.home.username} users -"
  ];

  # Configure Satty
  xdg.configFile."satty/config.toml".text = ''
    [general]
   
    early-exit = true
    initial-tool = "arrow"
    copy-command = "wl-copy"

    output-filename = "~/Pictures/Screenshots/satty-%Y%m%d-%H%M%S.png"
    
    [font]
    family = "JetBrainsMono Nerd Font"
  '';
}