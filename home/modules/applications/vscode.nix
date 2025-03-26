{ pkgs, ... }: {

    programs.vscode = {
        enable = true;
        
        profiles.default.userSettings = {
            "workbench.sideBar.location" = "right";
            "telemetry.telemetryLevel" = "off";
        };
    };

}