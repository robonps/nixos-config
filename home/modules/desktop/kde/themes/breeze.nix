{ pkgs, plasma-manager, ... }: {

    programs.plasma = {
        # Set the Breeze Dark theme for KDE Plasma
        workspace.lookAndFeel = "org.kde.breezedark.desktop";
    };
}