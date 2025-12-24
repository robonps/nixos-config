{ pkgs, ... }:
{
    imports = [
        ../modules/vscode/user.nix
    ];
    home.username = "robert";
    home.homeDirectory = "/home/robert";

    home.stateVersion = "25.11";

    home.pointerCursor = {
        gtk.enable = true;       # Applies to GTK apps (LibreWolf, File Manager)
        x11.enable = true;       # Applies to X11/Steam apps
        package = pkgs.volantes-cursors; 
        name = "volantes_cursors"; # The internal folder name of the theme
        size = 24;               # Standard size (try 32 if you want it bigger)
    };

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

                # 1. Force Websites to Dark Mode (Overrides privacy settings)
                "layout.css.prefers-color-scheme.content-override" = 0; # 0 = Dark, 1 = Light, 2 = System
                
                # 2. Make the Browser UI Dark
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

    home.packages = with pkgs; [

        # Terminal Utils
        fastfetch
        eza # ls alternative that is aliased in fish

        # Comms
        vesktop
    ];
}