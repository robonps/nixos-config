{ pkgs, ... }: {

    programs.vscode = {
        enable = true; # Enable VSCode

        profiles.default.userSettings = {
            "workbench.sideBar.location" = "right"; # Move sidebar to the right
            "telemetry.telemetryLevel" = "off"; # Disable telemetry
        };
    };

}