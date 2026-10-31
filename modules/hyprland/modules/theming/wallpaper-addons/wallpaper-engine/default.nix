{config, lib, pkgs, ...}: let
  cfg = config.custom.wallpaper.addons.wallpaperEngine;
in {
  options.custom.wallpaper.addons.wallpaperEngine = {
    enable = lib.mkEnableOption "Wallpaper Engine projects in the Quickshell wallpaper picker";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.linux-wallpaperengine;
      description = "Native renderer; override here to test a different package without a global overlay.";
    };
    assetsPath = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Absolute runtime path to Wallpaper Engine's assets directory; empty discovers it from Steam.";
    };
    workshopPaths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Absolute runtime paths to Steam workshop/content/431960 directories; empty discovers Steam libraries.";
    };
    enableWeb = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Expose experimental web projects; requires a working CEF backend in the selected renderer.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = (cfg.assetsPath == "" || lib.hasPrefix "/" cfg.assetsPath)
        && lib.all (lib.hasPrefix "/") cfg.workshopPaths;
      message = "Wallpaper Engine path overrides must be absolute; leave them empty for automatic Steam discovery.";
    }];
    custom.wallpaper.providers = [{
      id = "wallpaper-engine";
      module = ./provider.py;
      runtimeInputs = [cfg.package];
      settings = {
        executable = lib.getExe cfg.package;
        inherit (cfg) assetsPath workshopPaths enableWeb;
      };
    }];
  };
}
