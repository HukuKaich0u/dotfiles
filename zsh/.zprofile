# Linux login-shell zsh config distributed from the repo root.

path_prepend_if_dir() {
  if [ -d "$1" ]; then
    export PATH="$1:$PATH"
  fi
}

path_prepend_if_dir "$HOME/.npm-global/bin"
path_prepend_if_dir "$HOME/miniconda3/condabin"
path_prepend_if_dir "$HOME/miniconda3/bin"

if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
  . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi

if [ -x "$HOME/miniconda3/bin/conda" ]; then
  conda() {
    unset -f conda

    local conda_exe="$HOME/miniconda3/bin/conda"
    local __conda_setup

    __conda_setup="$("$conda_exe" 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
      eval "$__conda_setup"
    elif [ -f "$HOME/miniconda3/etc/profile.d/conda.sh" ]; then
      . "$HOME/miniconda3/etc/profile.d/conda.sh"
    fi

    unset __conda_setup conda_exe
    conda "$@"
  }
fi
