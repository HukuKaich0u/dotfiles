# Keep Herdr's config schema and executable together while nixpkgs lags upstream.
final: _prev: let
  version = "0.9.5";
  releases = {
    aarch64-darwin = {
      asset = "herdr-macos-aarch64";
      hash = "sha256-+3fCIyoFqANUITgsiUOS9BdOTjihjkivPdApAVfDp+I=";
    };
    x86_64-darwin = {
      asset = "herdr-macos-x86_64";
      hash = "sha256-X7CpCOx/Z0Xj4kVziwa/rVbEY5HDkas8CVX76tAfE2k=";
    };
    aarch64-linux = {
      asset = "herdr-linux-aarch64";
      hash = "sha256-F9dTby2lCFlSNoDvJ53/ysjkojX05G/o2mwuxEFBiXw=";
    };
    x86_64-linux = {
      asset = "herdr-linux-x86_64";
      hash = "sha256-FNnovItKngEY13wyJm921GHwm0A0LrI3UpYL2J9Zkp0=";
    };
  };
  release = releases.${final.stdenv.hostPlatform.system};
in {
  herdr = final.stdenvNoCC.mkDerivation {
    pname = "herdr";
    inherit version;
    src = final.fetchurl {
      url = "https://github.com/herdrdev/herdr/releases/download/v${version}/${release.asset}";
      inherit (release) hash;
    };

    dontUnpack = true;
    # Preserve the upstream Mach-O signature and the release binary's checksum.
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/herdr"
      runHook postInstall
    '';
    doInstallCheck = final.stdenv.buildPlatform.canExecute final.stdenv.hostPlatform;
    installCheckPhase = ''
      runHook preInstallCheck
      test "$("$out/bin/herdr" --version)" = "herdr ${version}"
      runHook postInstallCheck
    '';

    meta = {
      description = "Agent multiplexer that lives in your terminal";
      homepage = "https://herdr.dev";
      changelog = "https://github.com/herdrdev/herdr/releases/tag/v${version}";
      license = final.lib.licenses.asl20;
      sourceProvenance = [final.lib.sourceTypes.binaryNativeCode];
      mainProgram = "herdr";
      platforms = builtins.attrNames releases;
    };
  };
}
