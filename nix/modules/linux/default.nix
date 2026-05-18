{
  ...
}: {
  imports = [
    ../home/default.nix
    ./packages.nix
    ./zsh.nix
  ];

  home.username = "kokiaoyagi";
  home.homeDirectory = "/home/kokiaoyagi";
}
