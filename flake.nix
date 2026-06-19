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

    flake-utils = {
      url = "github:numtide/flake-utils";
    };

    main-hm-configuration = {
      url = "github:benraz123/home-manager-config";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixvim.follows = "nixvim";
      inputs.home-manager.follows = "home-manager";
      inputs.flake-utils.follows = "flake-utils";
    };

    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";
  };

  outputs =
    inputs@{
      flake-utils,
      apple-silicon,
      home-manager,
      nixpkgs,
      nixpkgs-patcher,
      ...
    }:
    let
      mkSys =
        {
          system,
          hostname,
          extraPkgsSettings ? { },
          extraModules ? [ ],
          extraPatches ? [ ],
        }:
        nixpkgs-patcher.lib.nixosSystem rec {
          nixpkgsPatcher.nixpkgs = nixpkgs;
          nixpkgsPatcher.patches =
            pkgs:
            with pkgs;
            [
              (fetchurl {
                name = "add-ensure-classes.patch";
                url = "https://github.com/NixOS/nixpkgs/pull/524127.diff";
                hash = "sha256-3n1i2rBm5qygoOkLNzihIJ0uYR6QdTLPKcukEJVl7BQ=";
              })
            ]
            ++ extraPatches;
          specialArgs = { inherit inputs system hostname; };
          modules = [
            ./hosts/${hostname}
            ./hosts/${hostname}/hardware-configuration.nix
            ./modules/common.nix
            ./modules/laptopBattery.nix
            ./modules/flatpak.nix
            ./modules/musicSync.nix

            extraPkgsSettings

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

      inherit (nixpkgs) lib;
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
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        formatter = pkgs.nixfmt-tree;
      }
    );
}
