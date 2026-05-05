#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
mise_nix="$repo_root/.config/nix/home-manager/mise.nix"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"

  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$home_nix" './mise.nix' \
  "home-manager should import mise.nix"
assert_contains "$mise_nix" 'programs.mise.enable = true;' \
  "mise.nix should enable programs.mise"
assert_contains "$mise_nix" 'programs.mise.enableZshIntegration = true;' \
  "mise.nix should enable zsh integration"
assert_contains "$mise_nix" 'globalConfig = {' \
  "mise.nix should define global config"
assert_contains "$mise_nix" 'tools = {' \
  "mise.nix should manage global tools through config.toml"
assert_contains "$mise_nix" 'settings = {' \
  "mise.nix should manage global settings through config.toml"

echo "mise home-manager bootstrap test passed"
