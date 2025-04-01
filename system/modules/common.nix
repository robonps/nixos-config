{ config, pkgs, ... }:

{
    imports = [
        ./virt.nix
    ];
    nix.settings.experimental-features = [ "nix-command" "flakes" ];

    nix.settings.auto-optimise-store = true;

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
        git
        nano
        curl
        tio
        home-manager
    ];

    fonts.packages = with pkgs; [
        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
    ];

    time.timeZone = "Pacific/Auckland";

    # Select internationalisation properties.
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


    # Configure keymap in the console and the interface.
    console.keyMap = "us";
    services.xserver.xkb = {
        layout = "us";
        variant = "";
    };


    networking.networkmanager.enable = true;


    # Firewall Ports
    # TCP
    # 22000 - Syncthing

    # UDP
    # 22000 - Syncthing
    # 21027 - Syncthing  
    networking.firewall.enable = true;
    networking.firewall.allowedTCPPorts = [22 80 443 22000];
    networking.firewall.allowedUDPPorts = [ 22000 21027 ];


    hardware.bluetooth.enable = true;
    services.blueman.enable = true;

    users.users.robert = {
        isNormalUser = true;
        extraGroups = [ "networkmanager" "wheel" ];
    };

}
