{
  pkgs,
  ...
}: let
  # Update Superpowers by bumping rev and hash together.
  superpowersSrc = pkgs.fetchFromGitHub {
    owner = "obra";
    repo = "superpowers";
    rev = "v5.1.0";
    hash = "sha256-3E3rO6hR87JUfS3XV1Eaoz6SDWOftleWvN9UPNFEMjw=";
  };
in {
  home.file.".agents/skills/superpowers".source = "${superpowersSrc}/skills";
}
