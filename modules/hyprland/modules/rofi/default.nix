{...}: {
  xdg.configFile."rofi/launcher.rasi".source = ./launcher.rasi;
  xdg.configFile."rofi/wallpaper.rasi".source = ./wallpaper.rasi;

  programs.rofi.enable = true;
}
