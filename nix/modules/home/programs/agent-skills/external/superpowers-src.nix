{
  pkgs,
  ...
}:
# Update Superpowers by bumping rev and hash together.
# Returns the upstream source derivation; `${src}/skills` holds the skill set.
pkgs.fetchFromGitHub {
  owner = "obra";
  repo = "superpowers";
  rev = "v5.1.0";
  hash = "sha256-3E3rO6hR87JUfS3XV1Eaoz6SDWOftleWvN9UPNFEMjw=";
}
