{
  description = "Ben Raz NixOS Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-yt-dlp.url = "github:nixos/nixpkgs/master";

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
      mkExtendedLib =
        args@{ pkgs, lib }:
        args.lib.extend (
          self: super:
          import ./lib/default.nix {
            inherit (args) pkgs;
            lib = self;
          }
        );

      mkPatched =
        {
          system,
          patches,
        }:
        let
          patchedNixpkgs = nixpkgs-patcher.lib.patchNixpkgs {
            inherit
              inputs
              system
              nixpkgs
              patches
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
          patches = (
            pkgs:
            with pkgs;
            [
              (fetchurl {
                name = "add-ensure-classes.patch";
                url = "https://github.com/NixOS/nixpkgs/pull/524127.diff";
                hash = "sha256-3ajlzrJfqsNqJzMPPkGuQm/kQnurkcKEe+qALP6AHsU=";
              })
            ]
            ++ extraPatches
          );

          pkgs = mkPatched { inherit system patches; };

          lib = mkExtendedLib {
            inherit pkgs;
            inherit (pkgs) lib;
          };
        in
        nixpkgs-patcher.lib.nixosSystem rec {
          nixpkgsPatcher = { inherit nixpkgs patches; };
          specialArgs = {
            inherit
              inputs
              system
              hostname
              lib
              ;
          };
          modules = [
            ./hosts/${hostname}
            ./hosts/${hostname}/hardware-configuration.nix
            ./modules/common.nix
            ./modules/flatpak.nix
            ./modules/laptopBattery.nix
            ./modules/musicSync.nix
            ./modules/symlinks.nix

            extraPkgsSettings

            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = specialArgs // {
                  lib = lib.extend (_: _: home-manager.lib);
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
          lib = mkExtendedLib {
            inherit pkgs;
            inherit (pkgs) lib;
          };
          extraSpecialArgs = {
            inherit inputs system;
          };
          modules = [ ./home/ben/generic/home.nix ];
        };
      }
    );
}
