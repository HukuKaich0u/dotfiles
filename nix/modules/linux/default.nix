{...}: {
  imports = [
    ../home/default.nix
    ./packages.nix
    ./bash.nix
  ];

  home.username = "kokiaoyagi";
  home.homeDirectory = "/home/kokiaoyagi";
}
