# Linux interactive zsh config distributed from the repo root.

path_prepend_if_dir() {
  if [ -d "$1" ]; then
    export PATH="$1:$PATH"
  fi
}

typeset -U path cdpath fpath manpath

for profile in ${(z)NIX_PROFILES}; do
  fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
done

autoload -Uz compinit

export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"

compinit -d "$ZSH_CACHE_DIR/.zcompdump"

path_prepend_if_dir "$HOME/.npm-global/bin"

if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

if [ -d "$HOME/.local/share/pnpm" ]; then
  case ":$PATH:" in
    *":$HOME/.local/share/pnpm:"*) ;;
    *) export PATH="$HOME/.local/share/pnpm:$PATH" ;;
  esac
  export PNPM_HOME="$HOME/.local/share/pnpm"
fi

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

if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

if [ -f "@zshAutosuggestions@" ]; then
  source "@zshAutosuggestions@"
fi

alias nv="nvim"
alias tm="tmux"
alias codex="codex --no-alt-screen"
alias codex-alt="command codex"
alias tmls="tmux list-sessions"
alias tma="tmux a -t"
alias tmnew="tmux new -s"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

bindkey -e
bindkey '^[^M' self-insert-unmeta

if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi

if [ -f "$HOME/.config/zsh/local.zsh" ]; then
  . "$HOME/.config/zsh/local.zsh"
fi

if [ -f "@zshSyntaxHighlighting@" ]; then
  source "@zshSyntaxHighlighting@"
fi
