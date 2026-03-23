# Enable multiline editing with Shift+Enter.
bindkey '^[^M' self-insert-unmeta

if command -v starship >/dev/null 2>&1; then
  eval "$(STARSHIP_CONFIG="$HOME/.config/starship.toml" starship init zsh)"
fi

_brew_formula_prefix() {
  local formula="$1"
  local prefix=""

  if command -v brew >/dev/null 2>&1; then
    prefix="$(brew --prefix "$formula" 2>/dev/null)" || prefix=""
  fi

  if [ -n "$prefix" ]; then
    printf '%s\n' "$prefix"
    return 0
  fi

  for prefix in /opt/homebrew /usr/local; do
    if [ -d "$prefix/opt/$formula" ]; then
      printf '%s\n' "$prefix/opt/$formula"
      return 0
    fi
  done

  return 1
}

_source_if_exists() {
  local file="$1"
  [ -f "$file" ] && source "$file"
}

typeset -r ZSH_AUTOSUGGESTIONS_PREFIX="$(_brew_formula_prefix zsh-autosuggestions 2>/dev/null)"
if [ -n "$ZSH_AUTOSUGGESTIONS_PREFIX" ]; then
  _source_if_exists "$ZSH_AUTOSUGGESTIONS_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

typeset -r ZSH_SYNTAX_HIGHLIGHTING_PREFIX="$(_brew_formula_prefix zsh-syntax-highlighting 2>/dev/null)"
if [ -n "$ZSH_SYNTAX_HIGHLIGHTING_PREFIX" ]; then
  _source_if_exists "$ZSH_SYNTAX_HIGHLIGHTING_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
