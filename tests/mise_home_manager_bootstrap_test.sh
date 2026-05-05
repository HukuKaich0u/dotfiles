#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/nix/home-manager/home.nix"
mise_nix="$repo_root/nix/home-manager/mise.nix"

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
assert_contains "$mise_nix" 'node = ' \
  "mise.nix should define a global node runtime"
assert_contains "$mise_nix" 'go = ' \
  "mise.nix should define a global go runtime"
assert_contains "$mise_nix" 'java = ' \
  "mise.nix should define a global java runtime"
assert_contains "$mise_nix" 'settings = {' \
  "mise.nix should manage global settings through config.toml"
assert_contains "$mise_nix" 'home.sessionPath = [' \
  "mise.nix should add a session path for corepack shims"
assert_contains "$mise_nix" '"$HOME/.local/bin"' \
  "mise.nix should place corepack shims under ~/.local/bin"
assert_contains "$mise_nix" 'home.activation.enableCorepack' \
  "mise.nix should enable corepack during home-manager activation"
assert_contains "$mise_nix" 'corepack enable --install-directory "$HOME/.local/bin"' \
  "mise.nix should enable corepack into ~/.local/bin"

echo "mise home-manager bootstrap test passed"
