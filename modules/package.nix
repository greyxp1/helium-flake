{
  stdenv,
  lib,
  makeWrapper,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  # Runtime/build deps
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
  version,
  src,
  flags ? [],
}: let
  commonFlags = [
    "--allow-file-access-from-files"
    "--disable-component-update"
    "--simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'"
    "--check-for-update-interval=0"
    "--no-first-run"
    "--enable-features=StorageAccessAPI,NativeNotifications,SystemNotifications,WaylandWindowDecorations"
  ];

  addFlags = lib.concatMapStringsSep " \\\n      " (f: "--add-flags \"${f}\"");

  # Libraries that must appear on LD_LIBRARY_PATH at runtime on Linux.
  linuxRuntimeLibs = [
    libGL
    libvdpau
    libva
    pipewire
    alsa-lib
    libpulseaudio
  ];
in
  stdenv.mkDerivation {
    pname = "helium";
    inherit version src;

    nativeBuildInputs = [
      makeWrapper
      autoPatchelfHook
      copyDesktopItems
    ];

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
    ];

    # Qt libraries are bundled; suppress autoPatchelf warnings for them.
    autoPatchelfIgnoreMissingDeps = [
      "libQt6Core.so.6"
      "libQt6Gui.so.6"
      "libQt6Widgets.so.6"
      "libQt5Core.so.5"
      "libQt5Gui.so.5"
      "libQt5Widgets.so.5"
    ];

    dontWrapQtApps = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/opt/helium
      cp -r * $out/opt/helium

      makeWrapper $out/opt/helium/helium $out/bin/helium \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath linuxRuntimeLibs}" \
        --add-flags "--ozone-platform-hint=auto" \
        ${addFlags (commonFlags ++ flags)}

      mkdir -p $out/share/icons/hicolor/256x256/apps
      cp $out/opt/helium/product_logo_256.png \
        $out/share/icons/hicolor/256x256/apps/helium.png

      runHook postInstall
    '';

    desktopItems = [
      (makeDesktopItem {
        name = "helium";
        exec = "helium %U";
        icon = "helium";
        desktopName = "Helium";
        genericName = "Web Browser";
        categories = ["Network" "WebBrowser"];
        terminal = false;
        mimeTypes = [
          "text/html"
          "text/xml"
          "application/xhtml+xml"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
      })
    ];

    meta = {
      description = "Private, fast, and honest web browser based on ungoogled-chromium";
      homepage = "https://helium.computer/";
      license = lib.licenses.gpl3Only;
      platforms = ["x86_64-linux"];
      mainProgram = "helium";
    };
  }
