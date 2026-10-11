{self}: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.helium;
  jsonFormat = pkgs.formats.json {};
  extensions = lib.attrValues cfg.extensions;
  pinnedExtensions = lib.filter (extension: extension.pin) extensions;
  extensionPolicies =
    lib.optionalAttrs (extensions != []) {
      ExtensionInstallForcelist = map (extension: extension.id) extensions;
    }
    // lib.optionalAttrs (pinnedExtensions != []) {
      ExtensionSettings = builtins.listToAttrs (map (extension: {
          name = lib.head (lib.splitString ";" extension.id);
          value.toolbar_pin = "force_pinned";
        })
        pinnedExtensions);
    };
  defaultPolicies = {
    RestoreOnStartup = 1;
    HighEfficiencyModeEnabled = true;
    MemorySaverModeSavings = 2;
  };
  defaultPreferences = {
    ntp.shortcust_visible = false;
    auto_pin_new_tab_groups = false;
    bookmark_bar.show_tab_groups = false;
    helium = {
      services.user_consented = true;
      browser = {
        layout = 2;
        mru_tab_cycling = true;
        show_avatar_button = false;
        rounded_frame = false;
        show_vertical_tabs_collapse_button = false;
      };
    };
  };
in {
  options.programs.helium = {
    enable = lib.mkEnableOption "Helium browser";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "inputs.helium.packages.\${pkgs.stdenv.hostPlatform.system}.default";
      description = "Helium package to use.";
    };
    flags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Extra command-line flags passed to Helium.";
    };
    extensions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          id = lib.mkOption {
            type = lib.types.str;
            description = "Extension ID, optionally followed by a semicolon and update URL.";
          };
          pin = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Force-pin the extension to the toolbar.";
          };
        };
      });
      default = {};
      description = "Extensions installed through system-wide Chromium policies.";
    };
    extensionPaths = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [];
      description = "Unpacked extensions copied to writable user data directories and loaded at startup.";
    };
    extraPolicies = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = {};
      description = "System-wide Chromium policies installed by the NixOS module.";
    };
    defaultBrowser = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Register Helium as the default browser.";
    };
    preferences = lib.mkOption {
      type = lib.types.attrsOf jsonFormat.type;
      default = {};
      description = "Preferences merged into the user's Default profile before a cold start.";
    };
    finalPolicyJson = lib.mkOption {
      type = lib.types.str;
      internal = true;
      readOnly = true;
      default = builtins.toJSON (lib.recursiveUpdate extensionPolicies cfg.extraPolicies);
    };
    finalPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      description = "Helium with the configured flags, preferences and unpacked extensions.";
      default = pkgs.callPackage ./configured-package.nix {inherit cfg;};
    };
  };

  config.programs.helium = {
    extraPolicies = lib.mapAttrsRecursive (_: lib.mkDefault) defaultPolicies;
    preferences = lib.mapAttrsRecursive (_: lib.mkDefault) defaultPreferences;
  };
}
