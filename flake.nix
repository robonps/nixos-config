{
    description = "My NixOS + Home-Manager Config";

    inputs = {
        # Define inputs for NixOS, Home Manager, and additional modules
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
        # Define the target system architecture
        system = "x86_64-linux";
        pkgs = import nixpkgs { inherit system; };

        # Default configuration values
        defaults = {
            desktopEnvironment = "gnome";
        };

    in {

        # Configuration for the "ThinkingBoi" system
        nixosConfigurations.thinkingboi = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
                ./system/thinkingboi/thinkingboi.nix
                home-manager.nixosModules.home-manager
                ({ config, pkgs, ... }: {
                    # Include the nxm package
                    environment.systemPackages = [
                        nxm.packages.${system}.default
                    ];
                })
            ];
            specialArgs = { inherit defaults; };
        };

        # Configuration for the "FastBoi" system
        nixosConfigurations.fastboi = nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
                ./system/fastboi/fastboi.nix
                home-manager.nixosModules.home-manager
            ];
            specialArgs = { inherit defaults; };
        };

        # Home Manager configuration for the "robert" user
        homeConfigurations.robert = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
                plasma-manager.homeManagerModules.plasma-manager
                nvf.homeManagerModules.default
                ./home/robert.nix
            ];
            # Pass default values to Home Manager
            extraSpecialArgs = { inherit defaults; };
        };

    };
}
