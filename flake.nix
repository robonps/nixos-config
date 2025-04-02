{
    description = "My NixOS + Home-Manager Config";

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
        
        home-manager.url = "github:nix-community/home-manager";
        home-manager.inputs.nixpkgs.follows = "nixpkgs";

        plasma-manager.url = "github:nix-community/plasma-manager";
        plasma-manager.inputs.nixpkgs.follows = "nixpkgs";
        plasma-manager.inputs.home-manager.follows = "home-manager";

        nvf.url = "github:notashelf/nvf";
        nvf.inputs.nixpkgs.follows = "nixpkgs";

        nxm.url = "github:robonps/nxm";
        nxm.inputs.nixpkgs.follows = "nixpkgs";
    };

    outputs = { nixpkgs, home-manager, plasma-manager, nvf, nxm, ... }: let
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };

        defaults = {
            desktopEnvironment = "gnome";
        };

    
    in {

        nixosConfigurations.thinkingboi = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
            ./system/thinkingboi/thinkingboi.nix
            home-manager.nixosModules.home-manager
            ({ config, pkgs, ... }: {
                environment.systemPackages = [
                    nxm.packages.${system}.default
                ];
            })
        ];
    
        };

        nixosConfigurations.fastboi = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
            ./system/fastboi/fastboi.nix
            home-manager.nixosModules.home-manager
        ];
    
        };


        homeConfigurations.robert = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
                plasma-manager.homeManagerModules.plasma-manager
                nvf.homeManagerModules.default
                ./home/robert.nix
            ];
            extraSpecialArgs = { inherit defaults; };
        };


    };
}
