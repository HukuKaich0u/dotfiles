{...}: {
  programs.zoxide = {
    enable = true;
    # shell-integrations.nix で事前生成した hook を読み込む。
    enableBashIntegration = false;
    enableZshIntegration = false;
  };
}
