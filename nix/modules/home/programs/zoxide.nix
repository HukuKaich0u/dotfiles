{...}: {
  programs.zoxide = {
    enable = true;
    # zsh-integrations.nix で事前生成した hook を読み込む。
    enableZshIntegration = false;
  };
}
