#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
config_nix="$repo_root/.config/nix/nix-darwin/configuration.nix"
home_manager_nix="$repo_root/.config/nix/nix-darwin/home_manager.nix"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"
  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_not_contains() {
  file="$1"
  needle="$2"
  message="$3"
  if grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$config_nix" 'system.stateVersion = 6;' \
  "configuration.nix must keep system.stateVersion"
assert_contains "$config_nix" 'system.configurationRevision = self.rev or self.dirtyRev or null;' \
  "configuration.nix must keep system.configurationRevision"
assert_contains "$config_nix" 'system.primaryUser = "KokiAoyagi";' \
  "configuration.nix must keep system.primaryUser"
assert_contains "$config_nix" 'users.users.KokiAoyagi.home = "/Users/KokiAoyagi";' \
  "configuration.nix must keep the user home path"
assert_contains "$config_nix" './home_manager.nix' \
  "configuration.nix must keep the home_manager import"

assert_not_contains "$config_nix" '../common/nixpkgs.nix' \
  "configuration.nix must remove the common nixpkgs import"
assert_not_contains "$config_nix" 'nix.enable = false;' \
  "configuration.nix must remove nix.enable"
assert_not_contains "$config_nix" 'system.defaults =' \
  "configuration.nix must remove macOS defaults"
assert_not_contains "$config_nix" 'nixpkgs.hostPlatform' \
  "configuration.nix must remove hostPlatform"
assert_not_contains "$config_nix" 'security.pam.services.sudo_local.touchIdAuth' \
  "configuration.nix must remove Touch ID sudo config"

assert_contains "$home_manager_nix" 'home-manager.users."KokiAoyagi" = ../home-manager/home.nix;' \
  "home_manager.nix must stay wired to home-manager/home.nix"

echo "nix-darwin reset test passed"
