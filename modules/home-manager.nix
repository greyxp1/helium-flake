{self}: {config, lib, pkgs, ...}: let
  cfg = config.programs.helium;

  configDir = "${config.xdg.configHome}/net.imput.helium/";

  fetchExtension = {id, hash}: let
    os =
      if pkgs.stdenv.isDarwin
      then "mac"
      else "linux";
    arch =
      if pkgs.stdenv.isAarch64
      then "arm64"
      else "x64";
    os_arch =
      if pkgs.stdenv.isDarwin
      then "arm64"
      else "x86_64";
    chromiumVersion = "148.0.0.0";
  in
    pkgs.fetchurl {
      name = "${id}.crx";
      url = "https://clients2.google.com/service/update2/crx?response=redirect&os=${os}&arch=${arch}&os_arch=${os_arch}&nacl_arch=x86-64&prod=chromiumcrx&prodchannel=stable&prodversion=${chromiumVersion}&acceptformat=crx3&x=id%3D${id}%26installsource%3Dondemand%26uc";
      inherit hash;
    };

  unpackExtension = {id, hash}:
    pkgs.runCommand "helium-ext-${id}"
    {
      nativeBuildInputs = [pkgs.unzip];
      src = fetchExtension {inherit id hash;};
    }
    ''
      mkdir -p $out
      unzip -q $src -d $out

      if [ ! -f "$out/manifest.json" ]; then
        echo "Extension ${id} did not unpack to a valid Chromium extension." >&2
        echo "Check the extension ID, hash, or Chrome Web Store rate limiting." >&2
        exit 1
      fi

      # Remove the system-reserved metadata folder that causes the load error
      rm -rf $out/_metadata
    '';

  resolvedExtensions = map (spec: {
    inherit (spec) id;
    unpacked = unpackExtension {inherit (spec) id hash;};
  })
  cfg.extensions;

  # We add the IDs to the Allowlist policy so Helium doesn't disable them for being "unverified"
  policyAttrs = {
    ExtensionInstallAllowlist = map (ext: ext.id) cfg.extensions;
  }
  // cfg.extraPolicies;

  loadExtensionFlag =
    if resolvedExtensions != []
    then ["--load-extension=${lib.concatStringsSep "," (map (ext: "${ext.unpacked}") resolvedExtensions)}"]
    else [];

  heliumWithFlags = pkgs.symlinkJoin {
    name = "helium-configured";
    paths = [cfg.package];
    nativeBuildInputs = [pkgs.makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/helium \
        ${lib.concatMapStringsSep " \\\n        " (f: "--add-flags ${lib.escapeShellArg f}") (
        [
          "--disable-component-update"
          "--allow-file-access-from-files"
        ]
        ++ loadExtensionFlag
        ++ lib.optionals pkgs.stdenv.isLinux [
          "--ozone-platform-hint=auto"
          "--enable-features=WaylandWindowDecorations,NativeNotifications,SystemNotifications"
        ]
        ++ cfg.extraFlags
      )}
    '';
  };
in {
  options.programs.helium = {
    enable = lib.mkEnableOption "Helium browser";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.helium;
    };
    extensions = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            id = lib.mkOption {type = lib.types.str;};
            hash = lib.mkOption {type = lib.types.str;};
          };
        }
      );
      default = [];
    };
    extraFlags = lib.mkOption {
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
      default = builtins.toJSON policyAttrs;
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
      packages = [
        heliumWithFlags
        pkgs.jq
        pkgs.coreutils
      ];

      file = let
        nativeMessagingHostsJoined = pkgs.symlinkJoin {
          name = "helium-native-messaging-hosts";
          paths = cfg.nativeMessagingHosts;
        };
      in {
        "${configDir}/NativeMessagingHosts" = lib.mkIf (cfg.nativeMessagingHosts != []) {
          source = "${nativeMessagingHostsJoined}/etc/chromium/native-messaging-hosts";
          recursive = true;
        };
      };

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

    xdg.mimeApps = lib.mkIf cfg.defaultBrowser {
      enable = true;
      defaultApplications = {
        "text/html" = "helium.desktop";
        "x-scheme-handler/http" = "helium.desktop";
        "x-scheme-handler/https" = "helium.desktop";
      };
    };
    xdg.desktopEntries.helium = lib.mkIf cfg.defaultBrowser {
      name = "Helium";
      exec = "${heliumWithFlags}/bin/helium %U";
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
}
