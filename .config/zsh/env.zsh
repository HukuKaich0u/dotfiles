source "$ZSH_CONFIG_DIR/homebrew.zsh"

export ZSH_STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
mkdir -p "$ZSH_STATE_DIR"
export HISTFILE="$ZSH_STATE_DIR/.zsh_history"

export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="/Users/KokiAoyagi/go/bin:$PATH"
export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:/usr/.local/bin"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"
export JAVA_HOME="/opt/homebrew/opt/openjdk"
export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:/Users/KokiAoyagi/include/"

# export PATH="$HOME/miniconda3/bin:$PATH"  # commented out by conda initialize
export PNPM_HOME="/Users/KokiAoyagi/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

. "$HOME/.local/bin/env"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/KokiAoyagi/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/KokiAoyagi/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/KokiAoyagi/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/KokiAoyagi/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/KokiAoyagi/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/KokiAoyagi/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/KokiAoyagi/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/KokiAoyagi/google-cloud-sdk/completion.zsh.inc'; fi
