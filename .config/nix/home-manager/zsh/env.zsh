source "$ZDOTDIR/homebrew.zsh"

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

export ZSH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
mkdir -p "$ZSH_STATE_DIR"
export HISTFILE="$ZSH_STATE_DIR/.zsh_history"

path_prepend_if_dir "$HOME/.npm-global/bin"
path_prepend_if_dir "${GOPATH:-$HOME/go}/bin"
path_prepend_if_dir "/opt/homebrew/opt/postgresql@17/bin"
path_prepend_if_dir "$HOME/.local/bin"
path_append_if_dir "/usr/local/bin"
path_append_if_dir "/usr/.local/bin"

if [ -d "/opt/homebrew/opt/openjdk" ]; then
  path_prepend_if_dir "/opt/homebrew/opt/openjdk/bin"
  export JAVA_HOME="/opt/homebrew/opt/openjdk"
fi

if [ -d "$HOME/include" ]; then
  export CPLUS_INCLUDE_PATH="${CPLUS_INCLUDE_PATH:+$CPLUS_INCLUDE_PATH:}$HOME/include"
fi

# export PATH="$HOME/miniconda3/bin:$PATH"  # commented out by conda initialize
if [ -d "$HOME/Library/pnpm" ]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
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

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

if [ -f "$ZDOTDIR/local.zsh" ]; then
  . "$ZDOTDIR/local.zsh"
fi
