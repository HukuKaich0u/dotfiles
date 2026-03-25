autoload -Uz compinit

export ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"

compinit -d "$ZSH_CACHE_DIR/.zcompdump"
