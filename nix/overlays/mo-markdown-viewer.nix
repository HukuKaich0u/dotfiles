# k1LoW/mo — Markdown viewer that opens .md files in a browser.
# Not in nixpkgs (the `mo` attr there is an unrelated mustache-templates
# tool for bash), so install the darwin release binary and override `mo`.
final: prev: {
  mo = final.stdenvNoCC.mkDerivation rec {
    pname = "mo";
    version = "1.6.3";
    src = final.fetchzip {
      url = "https://github.com/k1LoW/mo/releases/download/v${version}/mo_v${version}_darwin_arm64.zip";
      sha256 = "1yiyvir23yk6yrl0rfbw8lh5f4vd7n6q6kq1b0s4zlqyfpxsgwhb";
      stripRoot = false;
    };
    installPhase = ''
      runHook preInstall
      install -D -m755 mo $out/bin/mo
      runHook postInstall
    '';
    meta.platforms = [ "aarch64-darwin" ];
  };
}
