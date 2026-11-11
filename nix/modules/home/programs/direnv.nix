{ ... }: {
  # direnv evaluates a project's `.envrc` on `cd` (e.g. `use flake` to enter a
  # Nix devShell). This is separate from mise's own zsh integration, which only
  # switches runtimes from `.mise.toml`; mise cannot read `use flake`.
  programs.direnv = {
    enable = true;
    # shell-integrations.nix で事前生成した hook を読み込む。
    enableBashIntegration = false;
    enableZshIntegration = false;
    nix-direnv.enable = true;
  };
}
