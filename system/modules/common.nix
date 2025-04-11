{ pkgs, defaults, ... }:

let
    
    vars = import ../../vars.nix {inherit defaults; };
    desktopEnvironmentPath = ./desktop/${vars.desktopEnvironment}.nix;

in {
    # Import additional modules
    imports = [
        ./virt.nix
        desktopEnvironmentPath
    ];

    # Enable experimental Nix features
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    # Optimize Nix store
    nix.settings.auto-optimise-store = true;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;

    # Add common system packages
    environment.systemPackages = with pkgs; [
        git
        nano
        curl
        tio
        home-manager
    ];

    # Configure fonts
    fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
    ];

    # Set timezone
    time.timeZone = "Pacific/Auckland";

    # Configure internationalization settings
    i18n.defaultLocale = "en_NZ.UTF-8";
    i18n.extraLocaleSettings = {
        LC_ADDRESS = "en_NZ.UTF-8";
        LC_IDENTIFICATION = "en_NZ.UTF-8";
        LC_MEASUREMENT = "en_NZ.UTF-8";
        LC_MONETARY = "en_NZ.UTF-8";
        LC_NAME = "en_NZ.UTF-8";
        LC_NUMERIC = "en_NZ.UTF-8";
        LC_PAPER = "en_NZ.UTF-8";
        LC_TELEPHONE = "en_NZ.UTF-8";
        LC_TIME = "en_NZ.UTF-8";
    };

    # Configure keyboard layout
    console.keyMap = "us";
    services.xserver.xkb = {
        layout = "us";
        variant = "";
    };

    # Enable NetworkManager
    networking.networkmanager.enable = true;

    
    # Firewall Ports
    # TCP
    # 22000 - Syncthing

    # UDP
    # 22000 - Syncthing
    # 21027 - Syncthing
    networking.firewall.enable = true;
    networking.firewall.allowedTCPPorts = [22 80 443 22000];
    networking.firewall.allowedUDPPorts = [22000 21027];

    # Enable Bluetooth services
    hardware.bluetooth.enable = true;
    #services.blueman.enable = true;    # Don't Need.

    # Configure user settings
    users.users.robert = {
        isNormalUser = true;
        extraGroups = [ "networkmanager" "wheel" ];
    };
}
