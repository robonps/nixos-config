{
  description = "My NixOS + Home-Manager Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  
  in {

    nixosConfigurations.thinkingboi = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        ./hosts/thinkingboi/thinkingboi.nix
        home-manager.nixosModules.home-manager
      ];
  
    };


    homeConfigurations.robert = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [./home/robert.nix];
    };


  };
}
