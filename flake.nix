{
  description = "Ben Raz NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      apple-silicon,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      mkSys =
        {
          system,
          hostname,
          extraModules ? [ ],
        }:
        lib.nixosSystem rec {
          specialArgs = { inherit inputs system hostname; };
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          modules = [
            ./hosts/${hostname}
            ./hosts/${hostname}/hardware-configuration.nix
            ./modules/common.nix
            ./modules/laptopBattery.nix
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = specialArgs;
                users.ben = import ./home/ben;
              };
            }
          ]
          ++ extraModules;
        };
    in
    {
      # I decided to use space based names for my computers
      nixosConfigurations = {
        galaxy = mkSys {
          system = "aarch64-linux";
          hostname = "galaxy";
          extraModules = [
            apple-silicon.nixosModules.apple-silicon-support
          ];
        };
      };
    };
}
