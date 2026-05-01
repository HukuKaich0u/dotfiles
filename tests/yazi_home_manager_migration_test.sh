#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
yazi_nix="$repo_root/.config/nix/home-manager/yazi.nix"
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

  if [ -e "$path" ]; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$home_nix" './yazi.nix' \
  "home-manager should import yazi.nix"
assert_contains "$yazi_nix" 'programs.yazi = {' \
  "yazi.nix should configure programs.yazi"
assert_contains "$yazi_nix" 'shellWrapperName = "yy";' \
  "yazi.nix should pin the legacy shell wrapper name to avoid build warnings"
assert_contains "$install_sh" 'SKIP_CONFIG_DIRS="tmux zsh starship.toml yazi"' \
  "install.sh should skip yazi after the home-manager migration"
assert_not_exists "$repo_root/.config/yazi/yazi.toml" \
  "legacy yazi.toml should be removed from the symlink-managed config tree"

echo "yazi home-manager migration test passed"
