# yusukebe/ax — HTML を markdown にする CLI。imozuru の fetch.py があれば使う。
# nixpkgs に無く、upstream flake は bun2nix で source build になるため、
# darwin の release binary を入れる。
final: _prev: {
  ax = final.stdenvNoCC.mkDerivation rec {
    pname = "ax";
    version = "0.1.25";
    src = final.fetchurl {
      url = "https://github.com/yusukebe/ax/releases/download/v${version}/ax-darwin-arm64";
      hash = "sha256-lGM/nWHHQ8/89R5TOCidl0whQo77cL0plebG7BPgYsE=";
    };

    dontUnpack = true;
    # release binary に手を加えず、Bun が埋め込んだ bundle と署名をそのまま保つ。
    dontStrip = true;
    installPhase = ''
      runHook preInstall
      install -Dm755 "$src" "$out/bin/ax"
      runHook postInstall
    '';

    meta = {
      description = "The AI-era curl: fetch, discover, extract";
      homepage = "https://github.com/yusukebe/ax";
      license = final.lib.licenses.mit;
      sourceProvenance = [final.lib.sourceTypes.binaryNativeCode];
      mainProgram = "ax";
      platforms = ["aarch64-darwin"];
    };
  };
}
