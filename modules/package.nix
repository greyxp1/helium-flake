{
  stdenv,
  lib,
  makeWrapper,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  _7zz,
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
  kdePackages,
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
}:
let
  # Chromium flags applied on all platforms to disable update machinery.
  commonFlags = [
    "--disable-component-update"
    "--simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'"
    "--check-for-update-interval=0"
    "--no-first-run"
    "--enable-features=StorageAccessAPI"
    "--restore-last-session"
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
  ]
  ++ lib.optionals stdenv.isLinux [
    autoPatchelfHook
    copyDesktopItems
  ]
  ++ lib.optionals stdenv.isDarwin [ _7zz ];

  buildInputs = lib.optionals stdenv.isLinux [
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
    kdePackages.qtbase
  ];

  # Qt libraries are bundled; suppress autoPatchelf warnings for them.
  autoPatchelfIgnoreMissingDeps = lib.optionals stdenv.isLinux [
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
  ];

  dontWrapQtApps = stdenv.isLinux;

  unpackCmd = lib.optionalString stdenv.isDarwin "7zz x $src";

  installPhase =
    if stdenv.isDarwin then
      ''
        runHook preInstall

        mkdir -p $out/Applications/Helium.app
        cp -r . $out/Applications/Helium.app

        mkdir -p $out/bin
        makeWrapper $out/Applications/Helium.app/Contents/MacOS/Helium $out/bin/helium \
          ${addFlags commonFlags}

        runHook postInstall
      ''
    else
      ''
        runHook preInstall

        mkdir -p $out/bin $out/opt/helium
        cp -r * $out/opt/helium

        makeWrapper $out/opt/helium/helium $out/bin/helium \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath linuxRuntimeLibs}" \
          --add-flags "--ozone-platform-hint=auto" \
          --add-flags "--enable-features=WaylandWindowDecorations" \
          ${addFlags commonFlags}

        mkdir -p $out/share/icons/hicolor/256x256/apps
        cp $out/opt/helium/product_logo_256.png \
          $out/share/icons/hicolor/256x256/apps/helium.png

        runHook postInstall
      '';

  # Helper utility for getting extensions
  postInstall = ''
    mkdir -p $out/bin
    cp ${../scripts/prefetch-nix-extension.sh} $out/bin/prefetch-nix
    chmod +x $out/bin/prefetch-nix
  '';

  desktopItems = lib.optionals stdenv.isLinux [
    (makeDesktopItem {
      name = "helium";
      exec = "helium %U";
      icon = "helium";
      desktopName = "Helium";
      genericName = "Web Browser";
      categories = [
        "Network"
        "WebBrowser"
      ];
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
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "helium";
  };
}
