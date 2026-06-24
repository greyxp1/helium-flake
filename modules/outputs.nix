{inputs, self, ...}: {
  perSystem = {lib, pkgs, system, ...}: let
    sources = import ./sources.nix;

    version =
      if pkgs.stdenv.isDarwin
      then sources.versions.darwin
      else sources.versions.linux;

    src = pkgs.fetchurl (
      (sources.srcs.${system} or (throw "Unsupported system: ${system}")) sources.versions
    );

    helium = pkgs.callPackage ./package.nix {inherit version src;};

    app = {
      type = "app";
      program = "${helium}/bin/helium";
      meta = {
        inherit
          (helium.meta)
          description
          homepage
          license
          platforms
          ;
      };
    };

    moduleCheck = inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        inputs.home-manager.nixosModules.home-manager
        self.nixosModules.helium
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
              imports = [self.homeModules.helium];
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
    packages = {
      default = helium;
      inherit helium;
    };

    apps = {
      default = app;
      helium = app;
    };

    devShells.default = pkgs.mkShell {packages = [helium pkgs.nix-update];};
    checks = {build = helium;} // lib.optionalAttrs pkgs.stdenv.isLinux {
      module = moduleCheck.config.system.build.toplevel;
    };
  };
}
