# Linux login-shell zsh config distributed from the repo root.

path_prepend_if_dir() {
  if [ -d "$1" ]; then
    export PATH="$1:$PATH"
  fi
}

path_prepend_if_dir "$HOME/.npm-global/bin"

if [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
  . "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
fi

if [ -f "$HOME/.cargo/env" ]; then
  . "$HOME/.cargo/env"
fi
