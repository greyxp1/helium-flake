{
  stdenv,
  lib,
  makeWrapper,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libpulseaudio,
  libva,
  libvdpau,
  libx11,
  libxcb,
  libxcomposite,
  libxcursor,
  libxdamage,
  libxext,
  libxfixes,
  libxi,
  libxkbcommon,
  libxrandr,
  libxrender,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  libuuid,
  mesa,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
  vulkan-loader,
  wayland,
  ffmpeg,
  libkrb5,
  snappy,
  widevineCdm,
  version,
  src,
  flags ? [],
}: let
  desktop = makeDesktopItem {
    name = "helium";
    exec = "helium %U";
    icon = "helium";
    desktopName = "Helium";
    genericName = "Web Browser";
    categories = ["Network" "WebBrowser"];
    mimeTypes = [
      "application/pdf"
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "application/xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };

  mkFlag = f: "--add-flags \"${f}\"";
in
  stdenv.mkDerivation {
    pname = "helium";
    inherit version src;
    nativeBuildInputs = [makeWrapper autoPatchelfHook copyDesktopItems];
    buildInputs = [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      fontconfig
      freetype
      gdk-pixbuf
      glib
      gtk3
      libdrm
      libgbm
      libGL
      libpulseaudio
      libx11
      libxcb
      libxcomposite
      libxcursor
      libxdamage
      libxext
      libxfixes
      libxi
      libxkbcommon
      libxrandr
      libxrender
      libxscrnsaver
      libxshmfence
      libxtst
      libuuid
      mesa
      nspr
      nss
      pango
      pipewire
      systemd
      vulkan-loader
      wayland
      ffmpeg
      libkrb5
      snappy
      widevineCdm
    ];

    autoPatchelfIgnoreMissingDeps = [
      "libQt6Core.so.6"
      "libQt6Gui.so.6"
      "libQt6Widgets.so.6"
      "libQt5Core.so.5"
      "libQt5Gui.so.5"
      "libQt5Widgets.so.5"
    ];

    installPhase = ''
          runHook preInstall
          mkdir -p $out/bin $out/opt/helium
          cp -r * $out/opt/helium
          cp -a ${widevineCdm}/share/google/chrome/WidevineCdm $out/opt/helium/
          cat > $out/opt/helium/setup-widevine << 'WEOF'
      #!@shell@
      set -euo pipefail
      p="''${XDG_CONFIG_HOME:-$HOME/.config}/net.imput.helium/WidevineCdm"
      mkdir -p "$p"
      printf '{"Path":"%s"}' '@store@/opt/helium/WidevineCdm' > "$p/latest-component-updated-widevine-cdm"
      WEOF
          substituteInPlace $out/opt/helium/setup-widevine \
            --replace-fail '@shell@' '${stdenv.shell}' \
            --replace-fail '@store@' "$out"
          chmod +x $out/opt/helium/setup-widevine
          makeWrapper $out/opt/helium/helium-wrapper $out/bin/helium \
            --set CHROME_VERSION_EXTRA "Nix" \
            --set FONTCONFIG_FILE "${fontconfig.out}/etc/fonts/fonts.conf" \
            --prefix GSETTINGS_SCHEMAS_DIR : "${glib.getSchemaPath gtk3}" \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [libGL libvdpau libva pipewire alsa-lib libpulseaudio]}" \
            --add-flags "--ozone-platform-hint=auto" \
            ${lib.concatStringsSep " \\\n      " (map mkFlag ([
          "--no-first-run"
          "--disable-component-update"
          "--password-store=basic"
          "--check-for-update-interval=0"
          "--simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'"
          "--enable-features=StorageAccessAPI,NativeNotifications,SystemNotifications,WaylandWindowDecorations"
        ]
        ++ flags))} \
            --run $out/opt/helium/setup-widevine

          mkdir -p $out/share/icons/hicolor/256x256/apps
          cp product_logo_256.png $out/share/icons/hicolor/256x256/apps/helium.png
          runHook postInstall
    '';

    desktopItems = [desktop];
    meta = {
      description = "Private, fast, and honest web browser based on ungoogled-chromium";
      homepage = "https://helium.computer/";
      license = lib.licenses.gpl3Only;
      platforms = ["x86_64-linux"];
      mainProgram = "helium";
    };
  }
