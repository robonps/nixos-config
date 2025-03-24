{ pkgs, ... }: {

    programs.vscode = {
        enable = true;
        
        userSettings = {
            "workbench.sideBar.location": "right",
            "telemetry.telemetryLevel": "off"
        }
    };

}