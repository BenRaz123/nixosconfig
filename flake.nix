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
      patches = (
        pkgs: with pkgs; [
          (fetchurl {
            name = "add-ensure-classes.patch";
            url = "https://github.com/NixOS/nixpkgs/pull/524127.diff";
            hash = "sha256-3n1i2rBm5qygoOkLNzihIJ0uYR6QdTLPKcukEJVl7BQ=";
          })
        ]
      );

      mkPatched =
        {
          system,
          extraPatches ? [ ],
        }:
        let
          patches = patches ++ extraPatches;
          patchedNixpkgs = nixpkgs-patcher.lib.patchNixpkgs {
            inherit
              inputs
              system
              patches
              nixpkgs
              ;
          };
        in
        import patchedNixpkgs { inherit system; };

      mkSys =
        {
          system,
          hostname,
          extraPkgsSettings ? { },
          extraModules ? [ ],
          extraPatches ? [ ],
        }:
        let
          pkgs = mkPatched { inherit system extraPatches; };
        in
        nixpkgs-patcher.lib.nixosSystem rec {
          nixpkgsPatcher = { inherit nixpkgs patches; };
          specialArgs = {
            inherit inputs system hostname;
            lib = import ./lib/default.nix {
              inherit pkgs;
              inherit (pkgs) lib;
            };
          };
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
                extraSpecialArgs = specialArgs // {
                  lib = import ./lib/default.nix {
                    inherit pkgs;
                    inherit (home-manager) lib;
                  };
                };
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

        packages.homeConfigurations.ben = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./home/ben/generic/home.nix ];
        };
      }
    );
}
