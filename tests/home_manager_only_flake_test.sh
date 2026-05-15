#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
flake_nix="$repo_root/nix/flake.nix"
darwin_system="$repo_root/nix/modules/darwin/system.nix"
linux_home="$repo_root/nix/modules/linux/default.nix"

assert_contains() {
  file="$1"
  pattern="$2"
  message="$3"

  if ! grep -Fq "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$flake_nix" 'homeConfigurations."kokiaoyagi"' \
  "flake should keep the standalone home-manager configuration"
assert_contains "$flake_nix" 'home-manager.lib.homeManagerConfiguration' \
  "flake should keep the home-manager builder"
assert_contains "$flake_nix" './modules/home/default.nix' \
  "flake should wire the standalone home-manager entry to modules/home/default.nix"
assert_contains "$flake_nix" './modules/linux/default.nix' \
  "flake should wire the standalone home-manager entry to modules/linux/default.nix"
assert_contains "$flake_nix" 'darwinConfigurations."KokiAoyagi"' \
  "flake should expose a nix-darwin configuration entry point"
assert_contains "$flake_nix" 'nix-darwin.lib.darwinSystem' \
  "flake should build the darwin configuration through nix-darwin.lib.darwinSystem"
assert_contains "$flake_nix" 'home-manager.darwinModules.home-manager' \
  "flake should import the home-manager darwin module for nix-darwin wiring"
assert_contains "$flake_nix" './modules/darwin/system.nix' \
  "flake should wire darwinConfigurations to modules/darwin/system.nix"
assert_contains "$darwin_system" './home-manager.nix' \
  "darwin system should keep importing home-manager.nix"
assert_contains "$linux_home" '../home/default.nix' \
  "linux wrapper should import modules/home/default.nix"

echo "darwin and home-manager flake wiring test passed"
