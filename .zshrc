typeset -r DOTFILES_DIR="${0:A:h}"
typeset -r ZSHRC_TARGET="$DOTFILES_DIR/.config/zsh/.zshrc"

if [ -f "$ZSHRC_TARGET" ]; then
  source "$ZSHRC_TARGET"
fi
