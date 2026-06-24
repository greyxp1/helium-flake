_: {
  perSystem = {pkgs, system, ...}: let
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
  in {
    packages = {
      default = helium;
      inherit helium;
    };

    apps = {
      default = app;
      helium = app;
    };

    devShells.default = pkgs.mkShell {
      packages = [
        helium
        pkgs.nix-update
      ];
    };

    formatter = pkgs.nixfmt-tree;

    checks = {
      build = helium;
    };
  };
}
