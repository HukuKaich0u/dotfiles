typeset -r DOTFILES_DIR="${0:A:h}"
typeset -r ZPROFILE_TARGET="$DOTFILES_DIR/.config/zsh/.zprofile"

if [ -f "$ZPROFILE_TARGET" ]; then
  source "$ZPROFILE_TARGET"
fi
