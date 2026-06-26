{self}: {config, lib, options, ...}: let
  enabledUsers = lib.filterAttrs (_: user: user.programs.helium.enable or false) (config.home-manager.users or {});
  policyJsons = lib.unique (map (user: user.programs.helium.finalPolicyJson) (lib.attrValues enabledUsers));
in {
  config = lib.mkMerge [
    (lib.mkIf (options ? home-manager) {home-manager.sharedModules = [self.homeModules.helium];})
    (lib.mkIf (enabledUsers != {}) {
      assertions = lib.singleton {
        assertion = lib.length policyJsons == 1;
        message = "programs.helium policies are global; enabled Home Manager users must use identical policies.";
      };
      environment.etc = lib.genAttrs [
        "chromium/policies/managed/helium.json"
        "helium/policies/managed/helium.json"
      ] (_: {
        text = lib.head policyJsons;
        mode = "0644";
      });
    })
  ];
}
