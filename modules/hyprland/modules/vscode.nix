{pkgs, ...}: {
  programs.vscode.profiles.default = {
    extensions = with pkgs.vscode-marketplace; [
      # Publisher.ExtensionName
      hyprluna.hyprluna-theme
    ];

    userSettings = {
      "workbench.colorTheme" = "HyprLuna Material";
      "walTheme.autoUpdate" = true;
      "walTheme.reloadCustomizations" = true;
    };
  };
}
