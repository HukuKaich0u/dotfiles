#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
script="$repo_root/scripts/common/link-dotfiles.sh"
legacy_script="$repo_root/scripts/link-dotfiles.sh"

if [ ! -x "$script" ]; then
  echo "install script is not executable: $script"
  exit 1
fi

if [ ! -x "$legacy_script" ]; then
  echo "legacy install script wrapper is not executable: $legacy_script"
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

home_dir="$tmp_dir/home"
mkdir -p "$home_dir"
mkdir -p "$home_dir/.config"

ln -s "$repo_root/.config/nix" "$home_dir/.config/nix"
ln -s /tmp "$home_dir/.config/not-nix"

env -i HOME="$home_dir" PATH="/usr/bin:/bin" "$script" >/dev/null

assert_symlink() {
  target="$1"
  expected="$2"

  if [ ! -L "$target" ]; then
    echo "expected symlink: $target"
    exit 1
  fi

  actual="$(readlink "$target")"
  if [ "$actual" != "$expected" ]; then
    echo "unexpected symlink target for $target: $actual"
    exit 1
  fi
}

assert_absent() {
  target="$1"

  if [ -e "$target" ] || [ -L "$target" ]; then
    echo "expected link-dotfiles.sh not to manage: $target"
    exit 1
  fi
}

assert_absent "$home_dir/.gitconfig"
assert_absent "$home_dir/.gitconfig-personal"
assert_absent "$home_dir/.gitconfig-university"
assert_absent "$home_dir/.config/starship.toml"
assert_absent "$home_dir/.config/tmux"
assert_absent "$home_dir/.config/zsh"
assert_absent "$home_dir/.config/ghostty"
assert_absent "$home_dir/.config/nix"
assert_symlink "$home_dir/.config/not-nix" "/tmp"
assert_absent "$home_dir/.zshenv"
assert_absent "$home_dir/.zprofile"
assert_absent "$home_dir/.zshrc"
