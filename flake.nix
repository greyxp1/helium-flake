{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      flake.homeModules.helium = import ./modules/home-manager.nix {inherit (inputs) self;};
      flake.nixosModules.helium = import ./modules/nixos.nix {inherit (inputs) self;};
      perSystem = {pkgs, system, ...}: let
        helium = pkgs.callPackage ./modules/package.nix {
          widevineCdm = pkgs.widevine-cdm;
          version = "0.13.5.1";
          src = pkgs.fetchurl {
            url = "https://github.com/imputnet/helium-linux/releases/download/0.13.5.1/helium-0.13.5.1-x86_64_linux.tar.xz";
            hash = "sha256-70kkeycnB7Ouzt047NpD8O/5t5MO9sE8Qxcby7v3/mY=";
          };
        };
      in {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        packages.default = helium;
        packages.helium = helium;
        apps.default.type = "app";
        apps.default.program = "${helium}/bin/helium";
        apps.helium.type = "app";
        apps.helium.program = "${helium}/bin/helium";
        devShells.default = pkgs.mkShell {packages = [helium pkgs.nix-update];};
      };
    };
}
