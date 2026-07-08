{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    bitwig-studio

    decent-sampler
  ];

  home.file.".vst3" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/vst3";
    recursive = true;
  };

}

