{pkgs, ...}: {
  programs.steam = {
    enable = true;

    remotePlay.openFirewall = true;

    dedicatedServer.openFirewall = true;

    gamescopeSession.enable = true;
  };

  programs.gamemode.enable = true;

  environment.systemPackages = with pkgs; [
    mangohud # The FPS counter overlay
    protonup-qt # GUI to download custom Proton versions (GE-Proton)
  ];
}
