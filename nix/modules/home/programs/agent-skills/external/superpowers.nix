{
  pkgs,
  ...
}: let
  superpowersSrc = import ./superpowers-src.nix {inherit pkgs;};
in {
  home.file.".agents/skills/superpowers".source = "${superpowersSrc}/skills";
}
