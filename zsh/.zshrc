# Linux interactive zsh config distributed from the repo root.

typeset -U path cdpath fpath manpath

for profile in ${(z)NIX_PROFILES}; do
  fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
done

autoload -Uz compinit

export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"

compinit -d "$ZSH_CACHE_DIR/.zcompdump"

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

if [ -f "$HOME/.config/zsh/local.zsh" ]; then
  . "$HOME/.config/zsh/local.zsh"
fi

if [ -f "@zshSyntaxHighlighting@" ]; then
  source "@zshSyntaxHighlighting@"
fi
