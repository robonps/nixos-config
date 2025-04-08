{ pkgs, defaults, lib, ... }: 

let
    vars = import ../vars.nix { inherit defaults;};
    cleanedString = builtins.replaceStrings [ "[" "]" ] [ "" "" ] vars.enabledModules; 
    splitResult = lib.strings.split " " cleanedString;
    enabledModules = if builtins.length splitResult > 0 then splitResult else null;
in {
  
    # Import application-specific modules
    imports = [
        ./modules/applications
    ] ++ builtins.map (mod:
            ./modules/environments/${mod}
        ) enabledModules;

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
