{pkgs, ...}: {
  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Pacific/Auckland";

  # Keyring
  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;

  # Auto-unlock for whatever login manager you choose
  security.pam.services.sddm.enableGnomeKeyring = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

  services.gnome.glib-networking.enable = true;

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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "nz";
    variant = "";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.mutableUsers = true;
  users.users.robert = {
    isNormalUser = true;
    description = "Robert";
    extraGroups = ["networkmanager" "wheel"];
    packages = with pkgs; [];
  };

  # Enable Realtime Kit
  # This is critical. It allows the audio process to ask the kernel for
  # "Realtime Priority" so your audio doesn't crackle when the CPU is busy.
  security.rtkit.enable = true;

  # Enable Pipewire
  services.pipewire = {
    enable = true;

    # Compatibility layer for normal apps (Firefox, Discord, Spotify)
    pulse.enable = true;

    # Compatibility layer for low-level ALSA apps
    alsa.enable = true;
    alsa.support32Bit = true; # Needed for Steam games

    jack.enable = true;
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported
        # Bluetooth adapters. Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however
        # the tradeoff is increased power consumption. Defaults to
        # 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes
        # adapters present on start as well as adapters that are plugged
        # in later on. Defaults to 'true'.
        AutoEnable = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    bluetuith # Bluetooth tui

    pavucontrol # The standard "Volume Mixer" GUI. Simple, works perfectly.

    seahorse # Gnome Keyring App for viewing passwords.
  ];

  # Automatic Cleanup
  nix.settings.auto-optimise-store = true;
  # Nix Helper command
  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/home/robert/nixos-config";
  };

  # Enable Fish globally and set as default shell
  programs.fish.enable = true;
  users.users.robert.shell = pkgs.fish;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Enable Flakes
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
