{ pkgs, inputs, ... }: {
  home.packages = with pkgs; [
    (prismlauncher.override {
      additionalLibs = [
        libXtst 
        libxkbcommon     
        libXt  
        libX11     
        libXi        
      ];
    })

    inputs.hytale-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default


    osu-lazer-bin

    heroic # For Epic Games
    lutris # For GOG and other games

    opentrack # Head tracking software for flight simulators
  ];
}