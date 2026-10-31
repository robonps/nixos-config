{lib, ...}: {
  imports = [./wallpaper-engine];

  options.custom.wallpaper.providers = lib.mkOption {
    internal = true;
    default = [];
    description = "Packaged providers registered by optional wallpaper addons.";
    type = lib.types.listOf (lib.types.submodule {
      options = {
        id = lib.mkOption {type = lib.types.str;};
        module = lib.mkOption {type = lib.types.path;};
        settings = lib.mkOption {type = lib.types.attrs; default = {};};
        runtimeInputs = lib.mkOption {type = lib.types.listOf lib.types.package; default = [];};
      };
    });
  };
}
