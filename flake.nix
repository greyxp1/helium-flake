{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs: let
    mkHelium = pkgs: let
      version = "0.19.3.1";
      system = pkgs.stdenv.hostPlatform.system;
      arch =
        {
          x86_64-linux = "x86_64";
          aarch64-linux = "arm64";
        }.${
          system
        };
      hashes = {
        x86_64-linux = "sha256-j04BK12SH6WSaar5xUFgq/cpTGM7Gmql7bdyWUUxRXA=";
        aarch64-linux = "sha256-WIPQBbvCCSsnlmpgH3FT9EZkVpOCWjh8cLsi7YOhpvE=";
      };
    in
      pkgs.callPackage ./modules/package.nix {
        widevineCdm = pkgs.widevine-cdm;
        inherit version;
        src = pkgs.fetchurl {
          url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-${arch}_linux.tar.xz";
          hash = hashes.${system};
        };
      };
  in
    inputs.flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux"];
      flake.homeModules.helium = import ./modules/home-manager.nix {inherit (inputs) self;};
      flake.nixosModules.helium = import ./modules/nixos.nix {inherit (inputs) self;};
      perSystem = {
        pkgs,
        system,
        ...
      }: let
        helium = mkHelium pkgs;
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
