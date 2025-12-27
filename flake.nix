{
  description = "System NixOS Flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-vscode-extensions,
    ...
  } @ inputs: {
    nixosConfigurations.FastBoi = nixpkgs.lib.nixosSystem {

      specialArgs = { inherit inputs; };

      modules = [
        ./hosts/FastBoi/system.nix

        ({ config, pkgs, ... }: {
          nixpkgs.overlays = [
            inputs.nix-vscode-extensions.overlays.default
          ];
        })

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.robert = ./hosts/FastBoi/user.nix;

          home-manager.extraSpecialArgs = { inherit inputs; };
        }
      ];
    };
  };
}
