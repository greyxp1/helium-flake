{self}: {config, lib, pkgs, ...}: let
  cfg = config.programs.helium;
  configDir = "${config.xdg.configHome}/net.imput.helium/";
  helium = cfg.package.override {
    flags =
      [
        "--allow-file-access-from-files"
      ]
      ++ cfg.flags;
  };
in {
  options.programs.helium = {
    enable = lib.mkEnableOption "Helium browser";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.helium;
    };
    flags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
    };
    extraPolicies = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
    };
    defaultBrowser = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    nativeMessagingHosts = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [];
      example = lib.literalExpression ''
        [
          pkgs.keepassxc
        ]
      '';
      description = ''
        List of Helium browser native messaging hosts to install.
      '';
    };

    finalPolicyJson = lib.mkOption {
      type = lib.types.str;
      internal = true;
      default = builtins.toJSON cfg.extraPolicies;
    };

    preferences = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {};
      description = ''
        Chromium preferences to set in the Default profile.
        These are merged into ~/.config/net.imput.helium/Default/Preferences.
        Type: 'helium://prefs-internals/' to search for the json keys and values
      '';
      example = lib.literalExpression ''
        {
          "browser"."show_home_button" = true;
        }
      '';
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
              printf '%s\n' "$merged" > "$prefs_file"
            fi
          else
            printf '%s\n' "$nix_prefs" > "$prefs_file"
          fi
        '';
      };
    };

    xdg = {
      configFile = lib.mkIf (cfg.nativeMessagingHosts != []) (let
        nativeMessagingHostsJoined = pkgs.symlinkJoin {
          name = "helium-native-messaging-hosts";
          paths = cfg.nativeMessagingHosts;
        };
      in {
        "net.imput.helium/NativeMessagingHosts" = {
          source = "${nativeMessagingHostsJoined}/etc/chromium/native-messaging-hosts";
          recursive = true;
        };
      });
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
