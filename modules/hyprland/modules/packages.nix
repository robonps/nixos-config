{pkgs, ...}: {
  home.packages = with pkgs; [
    kdePackages.qtwayland # For Qt6 (NixOS 24.05+)
    qt5.qtwayland

    font-awesome_6 # Icon font

    awww # The Wallpaper Daemon (supports animations)
    quickshell # Animated desktop panels and the wallpaper carousel
    matugen # The Color Generator
    imagemagick # Thumbnail generation

    libnotify # Notification library
  ];
}
