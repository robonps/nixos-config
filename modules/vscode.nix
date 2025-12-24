{pkgs, ...}: {
  programs.vscode = {
    enable = true;

    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Nix Syntax
        jnoortheen.nix-ide
      ];

      userSettings = {
        # Font Settings
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'Droid Sans Mono', monospace";
        "editor.fontLigatures" = true;

        # UI Layout
        "workbench.sideBar.location" = "right";

        # Nix Ide settings
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nil";

        # Telemetry
        "telemetry.telemetryLevel" = "off";

        # Spacing
        "editor.tabSize" = 4;
        "editor.insertSpaces" = true;
        "editor.detectIndentation" = false;
      };
    };
  };

  home.packages = with pkgs; [
    nil
    nixpkgs-fmt
  ];
}
