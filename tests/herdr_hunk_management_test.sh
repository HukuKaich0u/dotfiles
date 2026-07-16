#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
flake_nix="$repo_root/nix/flake.nix"
darwin_home_manager_nix="$repo_root/nix/modules/darwin/home-manager.nix"
home_default_nix="$repo_root/nix/modules/home/default.nix"
hunk_nix="$repo_root/nix/modules/home/programs/hunk.nix"
darwin_homebrew_nix="$repo_root/nix/modules/darwin/homebrew.nix"

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

hunk_input_block="$({
  awk '
    /^[[:space:]]*hunk = \{/ { in_hunk = 1 }
    in_hunk { print }
    in_hunk && /^[[:space:]]*};[[:space:]]*$/ { exit }
  ' "$flake_nix"
})"

if [ -z "$hunk_input_block" ]; then
  echo "nix/flake.nix should declare the Hunk input"
  exit 1
fi

if ! printf '%s\n' "$hunk_input_block" | grep -Fq 'url = "github:modem-dev/hunk";'; then
  echo "the Hunk input should use the official modem-dev/hunk flake"
  exit 1
fi

if ! printf '%s\n' "$hunk_input_block" | grep -Fq 'inputs.nixpkgs.follows = "nixpkgs";'; then
  echo "the Hunk input should follow the shared nixpkgs input"
  exit 1
fi

assert_contains "$flake_nix" 'extraSpecialArgs = {inherit hunk;};' \
  "standalone Home Manager should receive the Hunk flake input"
assert_contains "$flake_nix" 'specialArgs = {inherit self hunk;};' \
  "nix-darwin should receive the self and Hunk flake inputs"
assert_contains "$darwin_home_manager_nix" '{hunk, ...}' \
  "the darwin Home Manager bridge should receive the Hunk flake input"
assert_contains "$darwin_home_manager_nix" 'home-manager.extraSpecialArgs = {inherit hunk;};' \
  "nix-darwin Home Manager users should receive the Hunk flake input"
assert_contains "$home_default_nix" 'hunk.homeManagerModules.default' \
  "the shared Home Manager tree should import Hunk's official module"
assert_contains "$home_default_nix" './programs/hunk.nix' \
  "the shared Home Manager tree should import the Hunk configuration"

if [ ! -f "$hunk_nix" ]; then
  echo "nix/modules/home/programs/hunk.nix should exist"
  exit 1
fi

assert_contains "$hunk_nix" 'programs.hunk = {' \
  "hunk.nix should configure programs.hunk"
assert_contains "$hunk_nix" 'enable = true;' \
  "hunk.nix should enable Hunk"
assert_contains "$hunk_nix" 'enableGitIntegration = false;' \
  "hunk.nix should leave Git integration disabled"
assert_contains "$hunk_nix" 'theme = "auto";' \
  "hunk.nix should use the automatic theme"
assert_contains "$hunk_nix" 'mode = "auto";' \
  "hunk.nix should use automatic mode"
assert_contains "$hunk_nix" 'exclude_untracked = false;' \
  "hunk.nix should include untracked files"
assert_contains "$hunk_nix" 'line_numbers = true;' \
  "hunk.nix should show line numbers"
assert_contains "$hunk_nix" 'wrap_lines = false;' \
  "hunk.nix should not wrap lines"
assert_contains "$hunk_nix" 'menu_bar = true;' \
  "hunk.nix should show the menu bar"
assert_contains "$hunk_nix" 'transparent_background = true;' \
  "hunk.nix should use a transparent background"

assert_not_contains "$darwin_homebrew_nix" '"hunk"' \
  "nix/modules/darwin/homebrew.nix should not manage the Hunk formula"

echo "Herdr and Hunk management tests passed"
