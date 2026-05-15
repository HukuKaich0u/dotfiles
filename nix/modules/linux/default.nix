{
  ...
}: {
  imports = [
    ../home/default.nix
    ./packages.nix
  ];

  home.username = "kokiaoyagi";
  home.homeDirectory = "/home/kokiaoyagi";
}
