#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
wezterm_nix="$repo_root/.config/nix/home-manager/wezterm.nix"
install_sh="$repo_root/install.sh"
wezterm_dir="$repo_root/.config/nix/home-manager/wezterm"

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

assert_contains "$home_nix" './wezterm.nix' \
  "home-manager should import wezterm.nix"

if [ ! -f "$wezterm_nix" ]; then
  echo "wezterm.nix should exist"
  exit 1
fi

if [ ! -f "$wezterm_dir/wezterm.lua" ]; then
  echo "home-manager wezterm.lua should exist"
  exit 1
fi

if [ ! -f "$wezterm_dir/keybinds.lua" ]; then
  echo "home-manager keybinds.lua should exist"
  exit 1
fi

assert_contains "$wezterm_nix" 'xdg.configFile."wezterm/wezterm.lua"' \
  "wezterm.nix should manage wezterm.lua through xdg.configFile"
assert_contains "$wezterm_nix" 'source = ./wezterm/wezterm.lua;' \
  "wezterm.nix should source wezterm.lua from the home-manager tree"
assert_contains "$wezterm_nix" 'xdg.configFile."wezterm/keybinds.lua"' \
  "wezterm.nix should manage keybinds.lua through xdg.configFile"
assert_contains "$wezterm_nix" 'source = ./wezterm/keybinds.lua;' \
  "wezterm.nix should source keybinds.lua from the home-manager tree"
assert_contains "$install_sh" 'SKIP_CONFIG_DIRS="tmux zsh starship.toml yazi bacon wezterm"' \
  "install.sh should skip wezterm after the home-manager migration"
assert_contains "$wezterm_dir/wezterm.lua" 'config.keys = require("keybinds").keys' \
  "home-manager wezterm.lua should keep the keybind loader"
assert_contains "$wezterm_dir/keybinds.lua" 'return {' \
  "home-manager keybinds.lua should keep the returned table"
assert_not_exists "$repo_root/.config/wezterm/wezterm.lua" \
  "legacy wezterm.lua should be removed from the symlink-managed config tree"
assert_not_exists "$repo_root/.config/wezterm/keybinds.lua" \
  "legacy keybinds.lua should be removed from the symlink-managed config tree"

echo "wezterm home-manager migration test passed"
