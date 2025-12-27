{...}: {
  programs.waybar.enable = true;
  xdg.configFile = {
    "waybar/config.jsonc".source = ./config.jsonc;
    "waybar/style.css".source = ./style.css;
  };

  home.file.".config/waybar/scripts/weather.sh" = {
    source = ./weather.sh;
    executable = true;
  };
}
