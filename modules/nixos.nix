{self}: {config, lib, options, ...}: let
  # Find all Home Manager users who enabled helium
  enabledUsers = lib.filterAttrs (_: user: user.programs.helium.enable or false) (
    config.home-manager.users or {}
  );

  # Generate etc files per user to support multi-user systems
  policyFiles = lib.mapAttrs' (
    name: user:
      lib.nameValuePair "chromium/policies/managed/helium-${name}.json" {
        text = user.programs.helium.finalPolicyJson;
        mode = "0644";
      }
  )
  enabledUsers // lib.mapAttrs' (
    name: user:
      lib.nameValuePair "helium/policies/managed/helium-${name}.json" {
        text = user.programs.helium.finalPolicyJson;
        mode = "0644";
      }
  )
  enabledUsers;
in {
  config = lib.mkMerge [
    (lib.mkIf (options ? home-manager) {
      home-manager.sharedModules = [self.homeModules.helium];
    })
    (lib.mkIf (enabledUsers != {}) {
      environment.etc = policyFiles;
    })
  ];
}
