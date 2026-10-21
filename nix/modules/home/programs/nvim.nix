{
  config,
  lib,
  pkgs,
  ...
}: {
  # Mason による端末ごとの最新解決を避け、flake.lock と一緒に更新する。
  # mise / project の PATH を妨げないよう、Neovim wrapper へ prefix しない。
  home.packages = with pkgs; [
    alejandra
    bash-language-server
    biome
    emmet-language-server
    gofumpt
    gopls
    gotools
    jdt-language-server
    nil
    prettier
    pyright
    ruff
    shellcheck
    shfmt
    stylua
    tailwindcss-language-server
    typos-lsp
    typescript-language-server
    vscode-langservers-extracted
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    withRuby = true;
  };

  xdg.configFile."nvim".source = ../assets/nvim;
  xdg.configFile."nvim-vscode".source = ../assets/nvim-vscode;

  # lazy.nvim が書き込める実ファイルへ、repo の共通 lock を反映する。
  # plugin の checkout は setup-user.sh の Lazy restore が担当する。
  home.activation.seedNeovimLock = lib.hm.dag.entryAfter ["writeBoundary"] ''
    install -Dm644 ${../assets/nvim/lazy-lock.json} "${config.xdg.stateHome}/nvim/lazy-lock.json"
  '';
}
