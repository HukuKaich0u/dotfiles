#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
starship_nix="$repo_root/.config/nix/home-manager/starship.nix"
zsh_nix="$repo_root/.config/nix/home-manager/zsh.nix"
zsh_dir="$repo_root/.config/nix/home-manager/zsh"
install_script="$repo_root/install.sh"

assert_contains() {
  file="$1"
  pattern="$2"
  message="$3"

  if ! grep -Fq "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_not_contains() {
  file="$1"
  pattern="$2"
  message="$3"

  if grep -Fq "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_missing() {
  path="$1"
  message="$2"

  if [ -e "$path" ] || [ -L "$path" ]; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$home_nix" "./zsh.nix" \
  "home.nix should import zsh.nix"
assert_contains "$home_nix" "./starship.nix" \
  "home.nix should import starship.nix"

if [ ! -f "$starship_nix" ]; then
  echo "starship.nix should exist"
  exit 1
fi

if [ ! -f "$zsh_nix" ]; then
  echo "zsh.nix should exist"
  exit 1
fi

assert_contains "$zsh_nix" 'programs.zsh = {' \
  "zsh.nix should configure programs.zsh"
assert_contains "$zsh_nix" 'dotDir = zshDotDir;' \
  "zsh.nix should route zsh through dotDir"
assert_contains "$zsh_nix" 'autosuggestion.enable = true;' \
  "zsh.nix should enable autosuggestions through Home Manager"
assert_contains "$zsh_nix" 'syntaxHighlighting.enable = true;' \
  "zsh.nix should enable syntax highlighting through Home Manager"
assert_contains "$zsh_nix" 'shellAliases = {' \
  "zsh.nix should manage aliases through programs.zsh.shellAliases"
assert_contains "$zsh_nix" 'nv = "nvim";' \
  "zsh.nix should keep core shell aliases"
assert_contains "$zsh_nix" 'autoload -Uz compinit' \
  "zsh.nix should inline completion initialization"
assert_contains "$zsh_nix" "bindkey '^[^M' self-insert-unmeta" \
  "zsh.nix should keep the multiline input bindkey in initContent"
assert_contains "$zsh_nix" 'if [ -e "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then' \
  "zsh.nix should source nix-daemon.sh after macOS path_helper runs"
assert_contains "$zsh_nix" 'source "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"' \
  "zsh.nix should restore nix profile paths in login shells"
assert_contains "$zsh_nix" 'path_prepend_if_dir "$HOME/.npm-global/bin"' \
  "zsh.nix should own the npm-global base path layer"
assert_contains "$zsh_nix" 'path_prepend_if_dir "/opt/homebrew/opt/postgresql@17/bin"' \
  "zsh.nix should own the shared PostgreSQL path layer"
assert_contains "$zsh_nix" 'path_prepend_if_dir "$HOME/.local/bin"' \
  "zsh.nix should own the user local bin layer"
assert_contains "$zsh_nix" 'path_append_if_dir "/usr/local/bin"' \
  "zsh.nix should append /usr/local/bin as a low-priority fallback"
assert_contains "$starship_nix" 'programs.starship = {' \
  "starship.nix should configure programs.starship"
assert_contains "$starship_nix" 'enable = true;' \
  "starship.nix should enable starship through Home Manager"
assert_contains "$starship_nix" 'settings = {' \
  "starship.nix should generate starship config from settings"
assert_contains "$starship_nix" 'docker_context = {' \
  "starship.nix should keep the custom docker context module"
assert_missing "$repo_root/.config/starship.toml" \
  "repo root should not keep a hand-managed starship.toml source"

for file in env.zsh homebrew.zsh; do
  if [ ! -f "$zsh_dir/$file" ]; then
    echo "missing zsh split file: $file"
    exit 1
  fi
done

assert_not_contains "$zsh_dir/env.zsh" 'source "$ZDOTDIR/homebrew.zsh"' \
  "env.zsh should not source homebrew.zsh after path responsibility cleanup"
assert_not_contains "$zsh_dir/env.zsh" '${GOPATH:-$HOME/go}/bin' \
  "env.zsh should not keep the legacy GOPATH bin path"

if [ -e "$zsh_dir/aliases.zsh" ] || [ -e "$zsh_dir/completion.zsh" ]; then
  echo "aliases and completion should be managed directly in zsh.nix"
  exit 1
fi

assert_contains "$install_script" 'HOME_DOTFILES=""' \
  "install.sh should stop linking zsh dotfiles"
assert_contains "$install_script" 'SKIP_CONFIG_DIRS="tmux zsh starship.toml yazi"' \
  "install.sh should stop linking .config/zsh and starship.toml"

assert_missing "$repo_root/.zshenv" \
  "repo root should not keep a hand-managed .zshenv entrypoint"
assert_missing "$repo_root/.zprofile" \
  "repo root should not keep a hand-managed .zprofile entrypoint"
assert_missing "$repo_root/.zshrc" \
  "repo root should not keep a hand-managed .zshrc entrypoint"

echo "zsh nix migration tests passed"
