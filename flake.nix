{
  description = "A Nix flake for the Helium browser";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      flake = {
        homeModules.helium = import ./modules/home-manager.nix {inherit (inputs) self;};
        nixosModules.helium = import ./modules/nixos.nix {inherit (inputs) self;};
      };

      perSystem = {pkgs, system, ...}: let
        version = "0.13.5.1";
        src = pkgs.fetchurl {
          url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
          hash = "sha256-70kkeycnB7Ouzt047NpD8O/5t5MO9sE8Qxcby7v3/mY=";
        };
        helium = pkgs.callPackage ./modules/package.nix {inherit version src;};
        app = {
          type = "app";
          program = "${helium}/bin/helium";
        };
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        packages = {
          default = helium;
          inherit helium;
        };

        apps = {
          default = app;
          helium = app;
        };

        devShells.default = pkgs.mkShell {packages = [helium pkgs.nix-update];};
      };
    };
}
