#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_default_nix="$repo_root/nix/modules/home/default.nix"
yazi_nix="$repo_root/nix/modules/home/programs/yazi.nix"
install_sh="$repo_root/scripts/common/link-dotfiles.sh"

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

assert_contains "$home_default_nix" './programs/yazi.nix' \
  "modules/home/default.nix should import programs/yazi.nix"
assert_contains "$yazi_nix" 'programs.yazi = {' \
  "yazi.nix should configure programs.yazi"
assert_contains "$yazi_nix" 'shellWrapperName = "yy";' \
  "yazi.nix should pin the legacy shell wrapper name to avoid build warnings"
if grep -Fq "REPO_CONFIG_DIR" "$install_sh"; then
  echo "link-dotfiles.sh should no longer distribute yazi via the removed .config tree"
  exit 1
fi
assert_not_exists "$repo_root/.config/yazi/yazi.toml" \
  "legacy yazi.toml should be removed from the symlink-managed config tree"

echo "yazi home-manager migration test passed"
