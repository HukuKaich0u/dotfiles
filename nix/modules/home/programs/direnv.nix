{...}: {
  # direnv evaluates a project's `.envrc` on `cd` (e.g. `use flake` to enter a
  # Nix devShell). This is separate from mise's own zsh integration, which only
  # switches runtimes from `.mise.toml`; mise cannot read `use flake`.
  # The direnv package itself is patched in overlays/direnv-no-zsh-check.nix to
  # skip a zsh test that hangs during the darwin build.
  programs.direnv = {
    enable = true;
    # zsh-integrations.nix で事前生成した hook を読み込む。
    enableZshIntegration = false;
    nix-direnv.enable = true;
  };
}
