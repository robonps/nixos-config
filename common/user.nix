{ pkgs, ... }:
{
    imports = [
        ../modules/vscode/user.nix
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
                "sidebar.revamp" = true;
                "sidebar.verticalTabs" = true;

                "privacy.clearOnShutdown.history" = false;
                "privacy.clearOnShutdown.cookies" = false;
            };
        };
    };

    home.packages = with pkgs; [
        
    ];
}