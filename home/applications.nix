{ pkgs, ... }: {
  
    imports = [
        ./modules/applications
    ];

    nixpkgs.config.allowUnfree = true;

    home.packages = with pkgs; [
        librewolf-bin
        vesktop
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

    targets.genericLinux.enable = true;
    xdg.mime.enable = true;

}