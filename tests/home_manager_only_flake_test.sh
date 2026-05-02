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

assert_contains "$flake_nix" 'homeConfigurations."KokiAoyagi"' \
  "flake should keep the standalone home-manager configuration"
assert_contains "$flake_nix" 'home-manager.lib.homeManagerConfiguration' \
  "flake should keep the home-manager builder"
assert_contains "$flake_nix" 'darwinConfigurations."KokiAoyagi"' \
  "flake should expose a nix-darwin configuration entry point"
assert_contains "$flake_nix" 'nix-darwin.lib.darwinSystem' \
  "flake should build the darwin configuration through nix-darwin.lib.darwinSystem"
assert_contains "$flake_nix" './nix-darwin/configuration.nix' \
  "flake should wire darwinConfigurations to nix-darwin/configuration.nix"
assert_contains "$darwin_config" './home_manager.nix' \
  "minimal nix-darwin config should keep importing home_manager.nix"

echo "darwin and home-manager flake wiring test passed"
