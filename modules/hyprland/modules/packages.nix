{pkgs, ...}: {
  home.packages = with pkgs; [
    kdePackages.qtwayland # For Qt6 (NixOS 24.05+)
    qt5.qtwayland

    font-awesome_6 # Icon font

    swww # The Wallpaper Daemon (supports animations)
    matugen # The Color Generator
    imagemagick # Thumbnail generation

    libnotify # Notification library
  ];
}
