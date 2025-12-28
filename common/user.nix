{pkgs, ...}: {
  imports = [
    ../modules/vscode.nix
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
    # Comms
    vesktop

    # Terminal Utils
    fastfetch
    eza # ls alternative that is aliased in fish
    killall
    ffmpeg

    # Other Utils
    easyeffects
  ];
}
