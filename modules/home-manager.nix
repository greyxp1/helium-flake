{self}: {
  config,
  lib,
  ...
}: let
  cfg = config.programs.helium;
in {
  imports = [(import ./options.nix {inherit self;})];

  config = lib.mkIf cfg.enable {
    home.packages = [cfg.finalPackage];
    home.sessionVariables = lib.mkIf cfg.defaultBrowser {BROWSER = "helium";};
    xdg.mimeApps = lib.mkIf cfg.defaultBrowser {
      enable = true;
      defaultApplications = {
        "text/html" = "helium.desktop";
        "x-scheme-handler/http" = "helium.desktop";
        "x-scheme-handler/https" = "helium.desktop";
      };
    };
  };
}
