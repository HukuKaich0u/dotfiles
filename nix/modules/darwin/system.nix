{
  self,
  pkgs,
  ...
}: {
  # This is the main nix-darwin config file.
  #
  # For now it is intentionally kept as a minimal bridge so darwin can own the
  # top-level machine entry point while existing user config stays in
  # ../home. As we rebuild darwin-side management, macOS-wide settings
  # such as homebrew, system.defaults, security, and users belong here.

  # Enable flakes / the new nix CLI for the bare `nix` command. direnv's
  # `use flake` and darwin-rebuild enable these on their own, so plain
  # `nix develop` / `nix flake` would otherwise fail with
  # "experimental Nix feature 'nix-command' is disabled".
  nix.settings.experimental-features = ["nix-command" "flakes"];

  # switch のたびに増える古い世代と /nix/store を定期的に掃除する。
  # 設定変更は 2 週に 1 回程度なので、30 日残せば直前の数世代へは戻せる。
  # root で走るこの GC は system の世代だけを消す。ユーザー側の世代は
  # ./default.nix の Home Manager 側 nix.gc が消す。
  nix.gc = {
    automatic = true;
    interval = [{Weekday = 7; Hour = 3; Minute = 15;}];
    options = "--delete-older-than 30d";
  };

  # nix-darwin requires its own state version for compatibility tracking.
  system.stateVersion = 6;
  # Record which dotfiles revision produced the current darwin configuration.
  system.configurationRevision = self.rev or self.dirtyRev or null;
  # Primary macOS user that darwin should treat as the owner of this machine.
  system.primaryUser = "KokiAoyagi";
  # Home path for that primary user on this Mac.
  users.users.KokiAoyagi.home = "/Users/KokiAoyagi";
  users.users.KokiAoyagi.shell = pkgs.zsh;

  # 補完とプロンプトは Home Manager が初期化する。
  # /etc/zshrc でも compinit を走らせると、毎回補完を二重に読み込む。
  programs.zsh.enableGlobalCompInit = false;
  programs.zsh.promptInit = "";

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
