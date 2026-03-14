export PATH="$HOME/.npm-global/bin:$PATH"

export PATH=/Users/KokiAoyagi/go/bin:$PATH
# export PATH="$PATH:/Users/KokiAoyagi/go/bin"

export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/usr/.local/bin
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"
export CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:/Users/KokiAoyagi/include/"
# export PATH="$HOME/miniconda3/bin:$PATH"  # commented out by conda initialize
export PNPM_HOME="/Users/KokiAoyagi/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

alias gotest='oj t -c "go run main.go" -d tests'
alias gobuild='go build -o main.out main.go'
alias gobintest='ojt -c "main/a.out"'
alias pytest='oj t -c "python3 main.py" -d tests'
alias rstest='oj t -c "rustc main.rs && ./main" -d tests'
alias rsbuild='rustc main.rs'
alias rsbintest='oj t -c "./main" -d tests'
. "$HOME/.local/bin/env"

alias nv='nvim'
alias tm='tmux'
alias codex='codex'
alias codex-inline='codex --no-alt-screen'

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

# Enable multiline editing with Shift+Enter
bindkey '^[^M' self-insert-unmeta
export PATH="$HOME/.local/bin:$PATH"

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/KokiAoyagi/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/KokiAoyagi/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/KokiAoyagi/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/KokiAoyagi/google-cloud-sdk/completion.zsh.inc'; fi

# pnpm
export PNPM_HOME="/Users/KokiAoyagi/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
