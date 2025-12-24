{pkgs, ...}: {
  wayland.windowManager.hyprland = {
    enable = true;

    # Systemd intergration
    systemd.enable = true;
  };

  xdg.portal = {
    enable = true;

    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland # The backend (screensharing, etc.)
      pkgs.xdg-desktop-portal-gtk # The FILE PICKER (Nautilus style)
    ];

    # The Config (Force Hyprland to use GTK for file picking)
    config = {
      hyprland = {
        default = ["hyprland"]; # Use Hyprland for most things
        "org.freedesktop.impl.portal.FileChooser" = ["gtk"]; # Use GTK for files!
      };
    };
  };
}
