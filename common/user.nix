{pkgs, ...}: {
  imports = [
    ../modules/vscode.nix
    ../modules/containers/user.nix # Podman container engine
  ];
  home.username = "robert";
  home.homeDirectory = "/home/robert";

  home.stateVersion = "25.11";

  programs.home-manager.enable = true;

  programs.git = {
    enable = true;
    settings.user = {
      name = "Robonps";
      email = "60711812+robonps@users.noreply.github.com";
    };
  };

  programs.librewolf = {
    enable = true;

    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;

      settings = {
        # Sidebar
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;

        # Privacy
        "privacy.clearOnShutdown.history" = false;
        "privacy.clearOnShutdown.cookies" = false;
        "network.cookie.lifetimePolicy" = 0;
        "privacy.sanitize.sanitizeOnShutdown" = false;
        "privacy.clearOnShutdown.cache" = false; # Often necessary to keep sessions alive
        "privacy.resistFingerprinting" = false;

        # Force Websites to Dark Mode (Overrides privacy settings)
        "layout.css.prefers-color-scheme.content-override" = 0; # 0 = Dark, 1 = Light, 2 = System

        # Make the Browser UI Dark
        "ui.systemUsesDarkTheme" = 1;
        "browser.theme.content-theme" = 0;
        "browser.in-content.dark-mode" = true;

        # Startup
        "browser.startup.page" = 3;
        "browser.sessionstore.restore_on_demand" = true;
        "network.captive-portal-service.enabled" = false;
      };
    };

    policies = {
      ExtensionSettings = {
        # Bitwarden
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
          installation_mode = "force_installed";
        };

        # Dark Reader
        "addon@darkreader.org" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          installation_mode = "force_installed";
        };

        # SponsorBlock
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
        };

        # Return YouTube Dislike
        "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/return-youtube-dislikes/latest.xpi";
          installation_mode = "force_installed";
        };

        # Hide YouTube Shorts
        "{88ebde3a-4581-4c6b-8019-2a05a9e3e938}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/hide-youtube-shorts/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable the "Welcome to Fish" message
    '';

    # Simple Aliases
    shellAliases = {
      l = "eza -lh --icons --git -a"; # Use 'eza' instead of 'ls' (install eza package!)
      lt = "eza --tree --level=2 --long --icons --git";
      v = "nvim";
      ".." = "cd ..";
    };
  };

  services.easyeffects = {
    enable = true;
  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };

  home.packages = with pkgs; [
    # GUI Apps
    orca-slicer
    localsend
    protonvpn-gui
    onlyoffice-desktopeditors
    mission-center
    celluloid # Video Player
    loupe # Image Viewer

    # Comms
    vesktop

    # Terminal Utils
    fastfetch
    eza # ls alternative that is aliased in fish
    killall
    ffmpeg
    yt-dlp # YouTube downloader

    # Other Utils
    easyeffects
  ];
}
