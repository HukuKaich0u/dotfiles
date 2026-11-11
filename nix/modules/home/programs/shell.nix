{
  config,
  lib,
  pkgs,
  ...
}:
{
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
  }
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    m = "mdp";
  };

  home.sessionPath = [
    "${config.home.homeDirectory}/.local/bin"
    "${config.home.homeDirectory}/.npm-global/bin"
    "${config.home.homeDirectory}/.cargo/bin"
  ];
  # Nix 側の Node.js 更新まで、修正版を mise で優先する。
  # NODE_OPTIONS の全体設定は Electron と互換性がないため使わない。
  programs.mise.globalConfig = lib.mkIf pkgs.stdenv.isDarwin {
    tools.node = "24.22.1";
  };

  home.sessionVariables = {
    BAT_THEME = "1337";
  }
  // lib.optionalAttrs pkgs.stdenv.isDarwin {
    # nix-darwin が nixpkgs の cacert から作る CA の一覧を使う。flake.lock の更新で新しくなる。
    # 消すと python.org 版の /usr/local/bin/python3 が HTTPS の証明書を検証できなくなる。
    SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    SSL_CERT_DIR = "/etc/ssl/certs";
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
  };
}
