#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
flake_nix="$repo_root/.config/nix/flake.nix"
darwin_config="$repo_root/.config/nix/nix-darwin/configuration.nix"

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

assert_contains "$flake_nix" 'homeConfigurations."KokiAoyagi"' \
  "flake should expose a standalone home-manager configuration"
assert_contains "$flake_nix" 'home-manager.lib.homeManagerConfiguration' \
  "flake should build home-manager without nix-darwin wiring"
assert_not_contains "$flake_nix" 'darwinConfigurations."aoyagikoukinoMacBook-Air"' \
  "flake should not expose an active nix-darwin configuration"
assert_not_contains "$darwin_config" 'programs.zsh.enable = true;' \
  "dormant nix-darwin config should not keep owning zsh"

echo "home-manager only flake test passed"
