{ pkgs, ... }: {

    # Exclude unnecessary GNOME packages
    environment.gnome.excludePackages = with pkgs; [
        atomix # puzzle game
        #cheese # webcam tool
        epiphany # web browser
        evince # document viewer
        geary # email reader
        gedit # text editor
        gnome-characters
        gnome-music
        gnome-photos
        #gnome-terminal
        gnome-tour
        hitori # sudoku game
        iagno # go game
        tali # poker game
        #totem # video player
    ];

    # Add GNOME-specific system packages
    environment.systemPackages = with pkgs; [
        gnome-tweaks
    ];

    # Enable X server and GNOME desktop environment
    services.xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
    };

    # Disable power profiles daemon
    services.power-profiles-daemon.enable = false;

}
