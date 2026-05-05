#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
bacon_nix="$repo_root/.config/nix/home-manager/bacon.nix"
install_sh="$repo_root/install.sh"

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

assert_contains "$home_nix" './bacon.nix' \
  "home-manager should import bacon.nix"

if [ ! -f "$bacon_nix" ]; then
  echo "bacon.nix should exist"
  exit 1
fi

assert_contains "$bacon_nix" 'programs.bacon = {' \
  "bacon.nix should configure programs.bacon"
assert_contains "$bacon_nix" 'enable = true;' \
  "bacon.nix should enable bacon through Home Manager"
assert_contains "$bacon_nix" 'settings = {' \
  "bacon.nix should manage bacon prefs through settings"
assert_contains "$bacon_nix" 'listen = true;' \
  "bacon.nix should preserve the listen setting"
assert_contains "$bacon_nix" 'exports.locations = {' \
  "bacon.nix should define exports.locations"
assert_contains "$bacon_nix" 'auto = true;' \
  "bacon.nix should preserve exports.locations.auto"
assert_contains "$bacon_nix" 'path = ".bacon-locations";' \
  "bacon.nix should preserve exports.locations.path"
assert_contains "$bacon_nix" 'line_format = "{item-idx}: {kind} {path}:{line}:{column} {message}";' \
  "bacon.nix should preserve exports.locations.line_format"
assert_contains "$install_sh" 'SKIP_CONFIG_DIRS="tmux zsh starship.toml yazi bacon"' \
  "install.sh should skip bacon after the home-manager migration"
assert_not_exists "$repo_root/.config/bacon/prefs.toml" \
  "legacy bacon prefs should be removed from the symlink-managed config tree"

echo "bacon home-manager migration test passed"
