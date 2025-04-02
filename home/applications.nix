{ pkgs, ... }: {
  
    # Import application-specific modules
    imports = [
        ./modules/applications
    ];

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # List of applications to install
    home.packages = with pkgs; [
        librewolf-bin
        vesktop
        signal-desktop
        protonvpn-gui
        vscode
        mission-center
        protonmail-bridge
        libreoffice-fresh
        hunspell
        hunspellDicts.en_AU-large
        mission-center
        fastfetch
        s-tui
        stress
        btop
    ];

    # Enable generic Linux targets and MIME support
    targets.genericLinux.enable = true;
    xdg.mime.enable = true;

}
