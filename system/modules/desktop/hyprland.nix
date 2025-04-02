{ pkgs, ... }: {

    # Enable SDDM display manager with Wayland support
    services = {
        displayManager.sddm.enable = true;
        displayManager.sddm.wayland.enable = true;
    };

    # Enable Hyprland with XWayland support
    programs.hyprland = {
        enable = true;
        xwayland.enable = true;
    };

    # Add system packages for Hyprland
    environment.systemPackages = with pkgs; [
        kitty
    ];

    # Set session variables for Wayland
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
}