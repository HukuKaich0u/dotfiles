{self, ...}: {
  system.stateVersion = 6;
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.primaryUser = "KokiAoyagi";
  users.users.KokiAoyagi.home = "/Users/KokiAoyagi";

  imports = [
    ./home_manager.nix
  ];
}
