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
        version = "0.13.4.1";
        src = pkgs.fetchurl {
          url = "https://github.com/imputnet/helium-linux/releases/download/${version}/helium-${version}-x86_64_linux.tar.xz";
          hash = "sha256-rt//wcAnH7n1ol/PfP37axHpIUKrWXSQN6SisGtE7hw=";
        };
        helium = pkgs.callPackage ./modules/package.nix {inherit version src;};
        app = {
          type = "app";
          program = "${helium}/bin/helium";
        };
        moduleCheck = inputs.nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            inputs.home-manager.nixosModules.home-manager
            inputs.self.nixosModules.helium
            {
              boot.loader.grub.devices = ["nodev"];
              fileSystems."/" = {
                device = "none";
                fsType = "tmpfs";
              };
              system.stateVersion = "26.05";
              users.users.helium-test = {
                isNormalUser = true;
                home = "/home/helium-test";
              };

              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.helium-test = {
                  home.enableNixpkgsReleaseCheck = false;
                  home.stateVersion = "26.05";
                  programs.helium = {
                    enable = true;
                    defaultBrowser = true;
                    extraPolicies.HomepageLocation = "https://helium.computer";
                    preferences.browser.show_home_button = true;
                  };
                };
              };
            }
          ];
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
        checks = {
          build = helium;
          module = moduleCheck.config.system.build.toplevel;
        };
      };
    };
}
