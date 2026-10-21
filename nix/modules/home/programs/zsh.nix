{
  config,
  lib,
  ...
}: let
  # Home Manager が生成する zsh 設定一式を ~/.config/zsh 配下に集約する。
  zshDotDir = "${config.home.homeDirectory}/.config/zsh";
in {
  programs.zsh = {
    enable = true;
    dotDir = zshDotDir;
    enableCompletion = true;
    completionInit = ''
      # 補完定義を読み込み、キャッシュを XDG cache 配下に置く。
      autoload -Uz compinit

      export ZSH_CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
      mkdir -p "$ZSH_CACHE_DIR"
      export ZSH_COMPDUMP="$ZSH_CACHE_DIR/.zcompdump"

      if [ -f "$ZSH_COMPDUMP" ]; then
        compinit -C -d "$ZSH_COMPDUMP"
      else
        compinit -d "$ZSH_COMPDUMP"
      fi
    '';
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.path = "${config.home.homeDirectory}/.local/state/zsh/.zsh_history";
    profileExtra = ''
      # ここは login shell の初期化。
      # コマンド解決と環境変数に関わるものは、対話操作より前にここでそろえる。
      # Homebrew や Nix の厳密な優先順位はここで作り込まず、
      # 自前で必要なものだけを明示的に PATH へ足す。

      if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
      fi

      # まず Homebrew の PATH を入れる。
      # `eval "$(brew shellenv)"` はコマンド置換を伴うため、pty なしの起動
      # (Cursor/VSCode の環境解決プローブ等) で zsh の SIGCHLD 取り逃しバグ
      # (zsh 5.9 で遭遇) を踏むと login shell 全体がハングする。
      # shellenv の出力は静的なので、同等の内容を fork なしで直接設定する。
      for brew_prefix in /opt/homebrew /usr/local; do
        if [ -x "$brew_prefix/bin/brew" ]; then
          export HOMEBREW_PREFIX="$brew_prefix"
          export HOMEBREW_CELLAR="$brew_prefix/Cellar"
          if [ "$brew_prefix" = "/usr/local" ]; then
            export HOMEBREW_REPOSITORY="/usr/local/Homebrew"
          else
            export HOMEBREW_REPOSITORY="$brew_prefix"
          fi
          # 共通 CLI は Nix を優先し、Homebrew の GUI / OS 専用ツールも使えるようにする。
          path+=("$brew_prefix/bin" "$brew_prefix/sbin")
          [ -z "''${MANPATH-}" ] || export MANPATH=":''${MANPATH#:}"
          export INFOPATH="$brew_prefix/share/info:''${INFOPATH:-}"
          fpath[1,0]="$brew_prefix/share/zsh/site-functions"
          break
        fi
      done

      # rustup/cargo が管理する PATH をそのまま読む。
      if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
      fi

      # ここから下は PATH 以外の環境変数。
      export BAT_THEME="1337"
      export ZSH_STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
      mkdir -p "$ZSH_STATE_DIR"
      export HISTFILE="$ZSH_STATE_DIR/.zsh_history"

      if [ -d "$HOME/include" ]; then
        export CPLUS_INCLUDE_PATH="''${CPLUS_INCLUDE_PATH:+$CPLUS_INCLUDE_PATH:}$HOME/include"
      fi
    '';
    initContent = lib.mkMerge [
      (lib.mkOrder 600 ''
        # ここから下は interactive shell 専用。
        # repo に入れないマシン固有の調整を最後に差し込む。
        if [ -f "$ZDOTDIR/local.zsh" ]; then
          . "$ZDOTDIR/local.zsh"
        fi
      '')
      (lib.mkOrder 1000 ''
        source ${config.xdg.configFile."zsh/integrations.zsh".source}

        # Ctrl+F などの標準的な行編集を安定させるため、interactive shell は Emacs keymap を明示する。
        bindkey -e

        # Shift+Enter が Esc+Enter として届く端末でも、複数行入力の改行として扱いやすくする。
        bindkey '^[^M' self-insert-unmeta
      '')
    ];
  };
}
