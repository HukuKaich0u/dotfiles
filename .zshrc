__dotfiles_source_zshrc() {
  local script_file="${${(%):-%N}:A}"
  local dotfiles_dir="${script_file:h}"
  local target="$dotfiles_dir/.config/zsh/.zshrc"

  if [ -f "$target" ]; then
    source "$target"
  fi
}

__dotfiles_source_zshrc
unset -f __dotfiles_source_zshrc
