{pkgs, ...}: {
  xdg.configFile."swaync/config.json".source = ./config.json;
  xdg.configFile."swaync/style.css".source = ./style.css;

  home.packages = [ pkgs.swaynotificationcenter];
}