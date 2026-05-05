#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/nix/home-manager/home.nix"
gh_nix="$repo_root/nix/home-manager/gh.nix"

if ! grep -Fq './gh.nix' "$home_nix"; then
  echo "home.nix should import gh.nix"
  exit 1
fi

if [ ! -f "$gh_nix" ]; then
  echo "gh.nix should exist"
  exit 1
fi

if ! grep -Fq 'programs.gh = {' "$gh_nix"; then
  echo "gh.nix should configure gh through programs.gh"
  exit 1
fi

if ! grep -Fq 'settings = {' "$gh_nix"; then
  echo "gh.nix should manage config.yml through programs.gh.settings"
  exit 1
fi

if ! grep -Fq 'aliases.co = "pr checkout";' "$gh_nix"; then
  echo "gh config should keep the pr checkout alias"
  exit 1
fi

if ! grep -Fq 'gitCredentialHelper.enable = true;' "$gh_nix"; then
  echo "gh git credential helper should be enabled through programs.gh"
  exit 1
fi

if ! grep -Fq '"gh/config.yml".force = true;' "$gh_nix"; then
  echo "gh config should forcefully replace the legacy config.yml"
  exit 1
fi

echo "gh config paths test passed"
