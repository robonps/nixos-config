{ pkgs, inputs, ... }: {
  home.packages = with pkgs; [
    (prismlauncher.override {
      additionalLibs = [
        xorg.libXtst 
        libxkbcommon     
        xorg.libXt  
        xorg.libX11     
        xorg.libXi        
      ];
    })

    inputs.hytale-launcher.packages.${pkgs.system}.default
  ];
}