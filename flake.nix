{
  description = "Ben Raz NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    main-hm-configuration = {
      url = "github:benraz123/home-manager-config";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixvim.follows = "nixvim";
      inputs.home-manager.follows = "home-manager";
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
      main-hm-configuration,
      ...
    }:
    let
      inherit (nixpkgs) lib;

      mkSys =
        {
          system,
          hostname,
          extraPkgsSettings ? { },
          extraModules ? [ ],
        }:
        lib.nixosSystem rec {
          specialArgs = { inherit inputs system hostname; };
          pkgs = import nixpkgs (
            lib.attrsets.recursiveUpdate {
              inherit system;
              config.allowUnfree = true;
            } extraPkgsSettings
          );
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

        pluto = mkSys {
          system = "x86_64-linux";
          hostname = "pluto";
          extraPkgsSettings = {
            config.allowInsecurePredicate = pkg: builtins.elem (lib.getName pkg) [ "broadcom-sta" ];
          };
        };
      };
    };
}
