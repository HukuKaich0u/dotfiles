{config, ...}: {
  # Shell ごとの alias の写しを作らない。Home Manager が bash / zsh へ配布する。
  home.shellAliases = {
    nv = "nvim";
    tm = "tmux";
    codex = "codex --no-alt-screen";
    codex-alt = "command codex";
    codex-work = "CODEX_HOME=$HOME/.codex-work codex";
    ghmp = "gh markdown-preview";
    tmls = "tmux list-sessions";
    tma = "tmux a -t";
    tmnew = "tmux new -s";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.npm-global/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];
  home.sessionVariables.BAT_THEME = "1337";
}
