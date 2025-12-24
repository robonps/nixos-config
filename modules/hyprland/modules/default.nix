{pkgs, ...}: {
  imports = [
    ./packages.nix
    ./kitty.nix
  ];
}
