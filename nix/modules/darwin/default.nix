{
  pkgs,
  ...
}: {
  imports = [
    ../home/default.nix
    ../home/programs/zsh.nix
    ./packages.nix
  ];

  home.username = "KokiAoyagi";
  home.homeDirectory = "/Users/KokiAoyagi";
}
