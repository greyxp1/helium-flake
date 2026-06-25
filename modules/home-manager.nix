{self}: {config, lib, pkgs, ...}: let
  cfg = config.programs.helium;
  configDir = "${config.xdg.configHome}/net.imput.helium/";
  extensions = lib.attrValues cfg.extensions;
  pinnedExtensions = lib.filter (extension: extension.pin) extensions;
  extensionPolicies = lib.optionalAttrs (extensions != []) {
    ExtensionInstallForcelist = map (extension: extension.id) extensions;
  } // lib.optionalAttrs (pinnedExtensions != []) {
    ExtensionSettings = builtins.listToAttrs (
      map (extension: {
        name = extension.id;
        value.toolbar_pin = "force_pinned";
      })
      pinnedExtensions
    );
  };
  helium = self.packages.${pkgs.stdenv.hostPlatform.system}.helium.override {inherit (cfg) flags;};
in {
  options.programs.helium = {
    enable = lib.mkEnableOption "Helium browser";
    flags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    extensions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          id = lib.mkOption {type = lib.types.str;};
          pin = lib.mkOption {
            type = lib.types.bool;
            default = false;
          };
        };
      });
      default = {};
    };
    extraPolicies = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
    };
    defaultBrowser = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    finalPolicyJson = lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = builtins.toJSON (lib.recursiveUpdate extensionPolicies cfg.extraPolicies);
    };

    preferences = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [helium];
      activation = lib.mkIf (cfg.preferences != {}) {
        heliumPreferences = lib.hm.dag.entryAfter ["writeBoundary"] ''
          prefs_dir="${configDir}/Default"
          prefs_file="$prefs_dir/Preferences"
          nix_prefs='${builtins.toJSON cfg.preferences}'

          run mkdir -p "$prefs_dir"

          if [ -f "$prefs_file" ]; then
            merged=$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$prefs_file" - <<< "$nix_prefs")
            if [ -n "$merged" ]; then
              run ${pkgs.runtimeShell} -c 'printf "%s\n" "$1" > "$2"' _ "$merged" "$prefs_file"
            fi
          else
            run ${pkgs.runtimeShell} -c 'printf "%s\n" "$1" > "$2"' _ "$nix_prefs" "$prefs_file"
          fi
        '';
      };
    };

    xdg = {
      mimeApps = lib.mkIf cfg.defaultBrowser {
        enable = true;
        defaultApplications = {
          "text/html" = "helium.desktop";
          "x-scheme-handler/http" = "helium.desktop";
          "x-scheme-handler/https" = "helium.desktop";
        };
      };
      desktopEntries.helium = lib.mkIf cfg.defaultBrowser {
        name = "Helium";
        exec = "${helium}/bin/helium %U";
        icon = "helium";
        terminal = false;
        categories = [
          "Network"
          "WebBrowser"
        ];
        mimeType = [
          "text/html"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
      };
    };
  };
}
