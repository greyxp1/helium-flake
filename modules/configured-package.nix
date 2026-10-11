{
  cfg,
  lib,
  symlinkJoin,
  makeWrapper,
  writeText,
  writeShellApplication,
  jq,
  coreutils,
}: let
  unpackedExtensions = lib.filterAttrs (_: extension: extension.install && extension.path != null) cfg.extensions;
  extensionDirectory = name: builtins.hashString "sha256" name;
  preferences = writeText "helium-preferences.json" (builtins.toJSON cfg.preferences);
  prepareProfile = writeShellApplication {
    name = "helium-prepare-profile";
    runtimeInputs = [coreutils] ++ lib.optional (cfg.preferences != {}) jq;
    text = ''
      browser_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/net.imput.helium"
      if [ -L "$browser_dir/SingletonLock" ]; then
        exit 0
      fi
      ${lib.optionalString (cfg.preferences != {}) ''
        prefs_dir="$browser_dir/Default"
        mkdir -p "$prefs_dir"
        prefs_file="$prefs_dir/Preferences"
        temporary=$(mktemp "$prefs_dir/.Preferences.XXXXXX")
        trap 'rm -f "$temporary"' EXIT
        if [ -f "$prefs_file" ]; then
          jq -s '.[0] * .[1]' "$prefs_file" ${preferences} > "$temporary"
        else
          cp ${preferences} "$temporary"
        fi
        mv "$temporary" "$prefs_file"
      ''}
      ${lib.optionalString (unpackedExtensions != {}) ''
        extension_root="''${XDG_DATA_HOME:-$HOME/.local/share}/helium/extensions"
        ${lib.concatMapAttrsStringSep "\n" (name: extension: let
            path = extension.path;
          in ''
            extension_dir="$extension_root/${extensionDirectory name}"
            if [ "$(cat "$extension_dir/.nix-source" 2>/dev/null)" != ${lib.escapeShellArg (toString path)} ]; then
              rm -rf "$extension_dir"
              mkdir -p "$extension_dir"
              cp -r ${lib.escapeShellArg "${path}/."} "$extension_dir/"
              chmod -R u+w "$extension_dir"
              printf '%s' ${lib.escapeShellArg (toString path)} > "$extension_dir/.nix-source"
            fi
          '')
          unpackedExtensions}
      ''}
    '';
  };
  extensionDirectories = map (name: "$extension_root/${extensionDirectory name}") (lib.attrNames unpackedExtensions);
  wrapperArgs =
    [
      "--add-flags"
      (lib.escapeShellArgs cfg.flags)
      "--inherit-argv0"
    ]
    ++ lib.optionals (cfg.preferences != {} || unpackedExtensions != {}) [
      "--run"
      (lib.getExe prepareProfile)
    ]
    ++ lib.optionals (unpackedExtensions != {}) [
      "--run"
      ''extension_root="''${XDG_DATA_HOME:-$HOME/.local/share}/helium/extensions"''
      "--add-flags"
      ''"--load-extension=${lib.concatStringsSep "," extensionDirectories}"''
    ];
in
  if cfg.flags == [] && cfg.preferences == {} && unpackedExtensions == {}
  then cfg.package
  else
    symlinkJoin {
      name = "${cfg.package.name}-configured";
      paths = [cfg.package];
      nativeBuildInputs = [makeWrapper];
      postBuild = ''
        wrapProgram "$out/bin/helium" ${lib.escapeShellArgs wrapperArgs}
      '';
      meta = cfg.package.meta;
    }
