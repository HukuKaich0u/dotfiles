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

      compinit -d "$ZSH_CACHE_DIR/.zcompdump"
    '';
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history.path = "${config.home.homeDirectory}/.local/state/zsh/.zsh_history";
    shellAliases = {
      nv = "nvim";
      tm = "tmux";
      codex = "codex --no-alt-screen";
      codex-alt = "command codex";
      tmls = "tmux list-sessions";
      tma = "tmux a -t";
      tmnew = "tmux new -s";
    };
    profileExtra = ''
      # ここは login shell の初期化。
      # コマンド解決と環境変数に関わるものは、対話操作より前にここでそろえる。
      # Homebrew や Nix の厳密な優先順位はここで作り込まず、
      # 自前で必要なものだけを明示的に PATH へ足す。

      # まず Homebrew の PATH を入れる。
      for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$brew_bin" ]; then
          eval "$("$brew_bin" shellenv)"
          break
        fi
      done

      # Nix も標準の初期化スクリプトに任せる。
      if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
      fi

      path_prepend_if_dir() {
        if [ -d "$1" ]; then
          export PATH="$1:$PATH"
        fi
      }

      # 標準では見つからない個人用コマンドだけを明示的に追加する。
      path_prepend_if_dir "$HOME/.npm-global/bin"

      # JDK は PATH と JAVA_HOME の両方が必要なので先に実体を探しておく。
      if [ -d "/opt/homebrew/opt/openjdk" ]; then
        path_prepend_if_dir "/opt/homebrew/opt/openjdk/bin"
      fi

      # rustup/cargo が管理する PATH をそのまま読む。
      if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
      fi

      # pnpm は専用の bin ディレクトリを持つので必要な時だけ追加する。
      if [ -d "$HOME/Library/pnpm" ]; then
        case ":$PATH:" in
          *":$HOME/Library/pnpm:"*) ;;
          *) export PATH="$HOME/Library/pnpm:$PATH" ;;
        esac
      fi

      # conda は公式が生成する hook を優先し、だめなら profile script / bin を使う。
      # >>> conda initialize >>>
      # !! Contents within this block are managed by 'conda init' !!
      if [ -x "$HOME/miniconda3/bin/conda" ]; then
        __conda_setup="$("$HOME/miniconda3/bin/conda" 'shell.zsh' 'hook' 2> /dev/null)"
        if [ $? -eq 0 ]; then
            eval "$__conda_setup"
        else
            if [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
                . "$HOME/miniconda3/etc/profile.d/conda.sh"
            else
                export PATH="$HOME/miniconda3/bin:$PATH"
            fi
        fi
        unset __conda_setup
      fi
      # <<< conda initialize <<<

      # gcloud 本体の PATH 追加。
      if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

      # ここから下は PATH 以外の環境変数。
      export ZSH_STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
      mkdir -p "$ZSH_STATE_DIR"
      export HISTFILE="$ZSH_STATE_DIR/.zsh_history"

      if [ -d "/opt/homebrew/opt/openjdk" ]; then
        export JAVA_HOME="/opt/homebrew/opt/openjdk"
      fi

      if [ -d "$HOME/include" ]; then
        export CPLUS_INCLUDE_PATH="''${CPLUS_INCLUDE_PATH:+$CPLUS_INCLUDE_PATH:}$HOME/include"
      fi

      if [ -d "$HOME/Library/pnpm" ]; then
        export PNPM_HOME="$HOME/Library/pnpm"
      fi

      # gcloud の補完は PATH 変更とは別なので最後に有効化する。
      if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
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
        # Ctrl+F などの標準的な行編集を安定させるため、interactive shell は Emacs keymap を明示する。
        bindkey -e

        # Shift+Enter が Esc+Enter として届く端末でも、複数行入力の改行として扱いやすくする。
        bindkey '^[^M' self-insert-unmeta
      '')
    ];
  };
}
