{ pkgs, ... }: {

    # Enable SDDM display manager with Wayland support and KDE Plasma
    services = {
        xserver.enable = true;
        displayManager.sddm.enable = true;
        displayManager.sddm.wayland.enable = true;
        desktopManager.plasma6.enable = true;
    };
}