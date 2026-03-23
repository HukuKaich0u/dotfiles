__dotfiles_source_zprofile() {
  local script_file="${${(%):-%N}:A}"
  local dotfiles_dir="${script_file:h}"
  local target="$dotfiles_dir/.config/zsh/.zprofile"

  if [ -f "$target" ]; then
    source "$target"
  fi
}

__dotfiles_source_zprofile
unset -f __dotfiles_source_zprofile
