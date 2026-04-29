#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
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

if [ ! -f "$zsh_nix" ]; then
  echo "zsh.nix should exist"
  exit 1
fi

assert_contains "$zsh_nix" 'programs.zsh = {' \
  "zsh.nix should configure programs.zsh"
assert_contains "$zsh_nix" 'dotDir = zshDotDir;' \
  "zsh.nix should route zsh through dotDir"
assert_contains "$zsh_nix" 'programs.starship.enable = true;' \
  "zsh.nix should manage starship through Home Manager"
assert_contains "$zsh_nix" 'autosuggestion.enable = true;' \
  "zsh.nix should enable autosuggestions through Home Manager"
assert_contains "$zsh_nix" 'syntaxHighlighting.enable = true;' \
  "zsh.nix should enable syntax highlighting through Home Manager"
assert_contains "$zsh_nix" 'shellAliases = {' \
  "zsh.nix should manage aliases through programs.zsh.shellAliases"
assert_contains "$zsh_nix" 'gotest = ' \
  "zsh.nix should keep competitive programming aliases"
assert_contains "$zsh_nix" 'autoload -Uz compinit' \
  "zsh.nix should inline completion initialization"
assert_contains "$zsh_nix" "bindkey '^[^M' self-insert-unmeta" \
  "zsh.nix should keep the multiline input bindkey in initContent"

for file in env.zsh homebrew.zsh; do
  if [ ! -f "$zsh_dir/$file" ]; then
    echo "missing zsh split file: $file"
    exit 1
  fi
done

if [ -e "$zsh_dir/aliases.zsh" ] || [ -e "$zsh_dir/completion.zsh" ]; then
  echo "aliases and completion should be managed directly in zsh.nix"
  exit 1
fi

assert_contains "$install_script" 'HOME_DOTFILES=""' \
  "install.sh should stop linking zsh dotfiles"
assert_contains "$install_script" 'SKIP_CONFIG_DIRS="tmux zsh"' \
  "install.sh should stop linking .config/zsh"

assert_missing "$repo_root/.zshenv" \
  "repo root should not keep a hand-managed .zshenv entrypoint"
assert_missing "$repo_root/.zprofile" \
  "repo root should not keep a hand-managed .zprofile entrypoint"
assert_missing "$repo_root/.zshrc" \
  "repo root should not keep a hand-managed .zshrc entrypoint"
assert_missing "$repo_root/.config/zsh/env.zsh" \
  "zsh source of truth should move under nix/home-manager/zsh"

echo "zsh nix migration tests passed"
