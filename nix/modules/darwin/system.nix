{self, ...}: {
  # This is the main nix-darwin config file.
  #
  # For now it is intentionally kept as a minimal bridge so darwin can own the
  # top-level machine entry point while existing user config stays in
  # ../home. As we rebuild darwin-side management, macOS-wide settings
  # such as homebrew, system.defaults, security, and users belong here.

  # nix-darwin requires its own state version for compatibility tracking.
  system.stateVersion = 6;
  # Record which dotfiles revision produced the current darwin configuration.
  system.configurationRevision = self.rev or self.dirtyRev or null;
  # Primary macOS user that darwin should treat as the owner of this machine.
  system.primaryUser = "KokiAoyagi";
  # Home path for that primary user on this Mac.
  users.users.KokiAoyagi.home = "/Users/KokiAoyagi";

  imports = [
    # Keep nixpkgs-level tweaks shared between standalone Home Manager and
    # darwin-driven evaluation.
    ../../lib/nixpkgs.nix
    # Keep the Home Manager wiring in a separate file so this darwin entry can
    # stay small and clearly focused on machine-level concerns.
    ./home-manager.nix
    # Keep Homebrew in its own module so package lists can grow there without
    # bloating this top-level darwin file.
    ./homebrew.nix
  ];
}
