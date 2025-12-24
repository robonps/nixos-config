{pkgs, ...}: {
  home.packages = with pkgs; [
    wofi # Menu

    kdePackages.qtwayland # For Qt6 (NixOS 24.05+)
    qt5.qtwayland
  ];
}
