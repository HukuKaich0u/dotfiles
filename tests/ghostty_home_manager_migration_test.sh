#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
ghostty_nix="$repo_root/nix/modules/home/programs/ghostty.nix"
ghostty_dir="$repo_root/nix/modules/home/assets/ghostty"
home_default_nix="$repo_root/nix/modules/home/default.nix"
install_sh="$repo_root/scripts/link-dotfiles.sh"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"

  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_not_exists() {
  path="$1"
  message="$2"

  if [ -e "$path" ] || [ -L "$path" ]; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$home_default_nix" './programs/ghostty.nix' \
  "modules/home/default.nix should import programs/ghostty.nix"

if [ ! -f "$ghostty_nix" ]; then
  echo "ghostty.nix should exist"
  exit 1
fi

if [ ! -f "$ghostty_dir/config" ]; then
  echo "home-manager ghostty config should exist"
  exit 1
fi

assert_contains "$ghostty_nix" 'xdg.configFile."ghostty/config"' \
  "ghostty.nix should manage config through xdg.configFile"
assert_contains "$ghostty_nix" 'source = ../assets/ghostty/config;' \
  "ghostty.nix should source config from the assets tree"
assert_contains "$install_sh" 'SKIP_CONFIG_DIRS="tmux zsh starship.toml yazi bacon wezterm ghostty nvim"' \
  "link-dotfiles.sh should skip ghostty after the home-manager migration"
assert_contains "$ghostty_dir/config" 'Managed by Home Manager.' \
  "home-manager ghostty config should be repo-managed"
assert_not_exists "$repo_root/.config/ghostty/config" \
  "legacy ghostty config should not exist in the symlink-managed config tree"

echo "ghostty home-manager migration test passed"
