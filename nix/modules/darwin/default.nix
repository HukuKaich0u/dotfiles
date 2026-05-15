{
  pkgs,
  ...
}: {
  imports = [
    ../home/default.nix
    ./packages.nix
  ];

  home.username = "KokiAoyagi";
  home.homeDirectory = "/Users/KokiAoyagi";
}
