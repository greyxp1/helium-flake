{
  versions = {
    linux = "0.12.3.1";
    darwin = "0.12.3.1";
  };

  srcs = {
    x86_64-linux = versions: {
      url = "https://github.com/imputnet/helium-linux/releases/download/${versions.linux}/helium-${versions.linux}-x86_64_linux.tar.xz";
      hash = "sha256-a4kcudN+bsOV253BSmTFsx0Tngmr/jbUd/A1gesc6QE=";
    };
    aarch64-linux = versions: {
      url = "https://github.com/imputnet/helium-linux/releases/download/${versions.linux}/helium-${versions.linux}-arm64_linux.tar.xz";
      hash = "sha256-GN/k/5mkazNPY1TGOGwJVYdM0YR805/2HHVGY6e1+9c=";
    };
    x86_64-darwin = versions: {
      url = "https://github.com/imputnet/helium-macos/releases/download/${versions.darwin}/helium_${versions.darwin}_x86_64-macos.dmg";
      hash = "sha256-8L0svl4gmUIbVF6C5TGpyivNXPsVIGyKPEydHf+GY0E=";
    };
    aarch64-darwin = versions: {
      url = "https://github.com/imputnet/helium-macos/releases/download/${versions.darwin}/helium_${versions.darwin}_arm64-macos.dmg";
      hash = "sha256-BrbexBlCQh9htQEy4Wiul/oNSn2MVERoqpLT8VRLENM=";
    };
  };
}
