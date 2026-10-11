{self}: {
  config,
  lib,
  ...
}: let
  cfg = config.programs.helium;
in {
  imports = [(import ./options.nix {inherit self;})];

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [cfg.finalPackage];
    environment.etc = lib.genAttrs [
      "chromium/policies/managed/helium.json"
      "helium/policies/managed/helium.json"
    ] (_: {text = cfg.finalPolicyJson;});
    environment.sessionVariables = lib.mkIf cfg.defaultBrowser {BROWSER = "helium";};
    xdg.mime = lib.mkIf cfg.defaultBrowser {
      enable = true;
      defaultApplications = {
        "text/html" = "helium.desktop";
        "x-scheme-handler/http" = "helium.desktop";
        "x-scheme-handler/https" = "helium.desktop";
      };
    };
  };
}
