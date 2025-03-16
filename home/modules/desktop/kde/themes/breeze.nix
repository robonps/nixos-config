{ pkgs, plasma-manager, ... }: {

    programs.plasma = {
        # Theming Settings
        workspace.lookAndFeel = "org.kde.breezedark.desktop";
    };
}