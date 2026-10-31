{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    bitwig-studio
  ];

  home.file.".vst3" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/vst3";
  };

  home.file.".vst" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/vst";
  };

  home.file.".clap" = {
    source = config.lib.file.mkOutOfStoreSymlink "${config.home.profileDirectory}/lib/clap";
  };

}

