#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
flake_nix="$repo_root/nix/flake.nix"
common_nixpkgs_nix="$repo_root/nix/common/nixpkgs.nix"
darwin_config_nix="$repo_root/nix/nix-darwin/configuration.nix"
overlay_nix="$repo_root/nix/common/direnv-no-zsh-check-overlay.nix"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"

  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$flake_nix" './common/direnv-no-zsh-check-overlay.nix' \
  "standalone home-manager pkgs import should include the direnv overlay"
assert_contains "$common_nixpkgs_nix" './direnv-no-zsh-check-overlay.nix' \
  "shared nixpkgs config should include the direnv overlay"
assert_contains "$darwin_config_nix" '../common/nixpkgs.nix' \
  "darwin configuration should import shared nixpkgs config"
assert_contains "$overlay_nix" 'make test-go test-bash test-fish' \
  "overlay should keep non-zsh direnv checks"
assert_contains "$overlay_nix" 'test-zsh' \
  "overlay should document the skipped direnv zsh check"

echo "direnv zsh check skip test passed"
