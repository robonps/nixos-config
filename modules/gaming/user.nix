{ pkgs, inputs, ... }: {
  home.packages = with pkgs; [
    (prismlauncher.override {
      additionalLibs = [
        libxtst 
        libxkbcommon     
        libxt  
        libx11     
        libxi        
      ];
    })

    inputs.hytale-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default


    osu-lazer-bin

    heroic # For Epic Games
    #lutris # For GOG and other games

    limo # Modding tool for games
  ];
}