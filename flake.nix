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
        version = "0.14.5.1";
        helium = pkgs.callPackage ./modules/package.nix {
          widevineCdm = pkgs.widevine-cdm;
          inherit version;
          src = pkgs.fetchurl {
            url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
            hash = "sha256-xm/dlEYoysEc92iGfguMSciDDUSAa/Mtvtn/HWSBrLE=";
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
