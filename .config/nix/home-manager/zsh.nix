{
  config,
  lib,
  ...
}: let
  zshDotDir = "${config.home.homeDirectory}/.config/zsh";
in {
  programs.zsh = {
    enable = true;
    dotDir = zshDotDir;
    enableCompletion = true;
    completionInit = ''
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
      for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew; do
        if [ -x "$brew_bin" ]; then
          eval "$("$brew_bin" shellenv)"
          break
        fi
      done

      if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
      fi
    '';
    initContent = lib.mkMerge [
      (lib.mkOrder 500 ''
        path_prepend_if_dir() {
          if [ -d "$1" ]; then
            export PATH="$1:$PATH"
          fi
        }

        path_append_if_dir() {
          if [ -d "$1" ]; then
            export PATH="$PATH:$1"
          fi
        }

        # Keep the base toolchain layer ordered as nix > homebrew.
        path_prepend_if_dir "$HOME/.npm-global/bin"
        path_prepend_if_dir "/opt/homebrew/opt/postgresql@17/bin"
        path_prepend_if_dir "$HOME/.local/bin"
        path_append_if_dir "/usr/local/bin"
        path_append_if_dir "/usr/.local/bin"

        if [ -d "/opt/homebrew/opt/openjdk" ]; then
          path_prepend_if_dir "/opt/homebrew/opt/openjdk/bin"
        fi

        if [ -f "$HOME/.cargo/env" ]; then
          . "$HOME/.cargo/env"
        fi

        if [ -d "$HOME/Library/pnpm" ]; then
          case ":$PATH:" in
            *":$HOME/Library/pnpm:"*) ;;
            *) export PATH="$HOME/Library/pnpm:$PATH" ;;
          esac
        fi

        if [ -f "$HOME/.local/bin/env" ]; then
          . "$HOME/.local/bin/env"
        fi

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

        if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

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

        if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
      '')
      (lib.mkOrder 600 ''
        if [ -f "$ZDOTDIR/local.zsh" ]; then
          . "$ZDOTDIR/local.zsh"
        fi
      '')
      (lib.mkOrder 1000 ''
        # Shift+Enter が Esc+Enter として届く端末でも、複数行入力の改行として扱いやすくする。
        bindkey '^[^M' self-insert-unmeta
      '')
    ];
  };
}
