#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
gitconfig_university="$repo_root/.config/nix/home-manager/git/config-university"

if ! grep -Fq 'programs.git = {' "$home_nix"; then
  echo "home-manager should configure git through programs.git"
  exit 1
fi

if ! grep -Fq 'condition = "gitdir:~/Documents/repos/university/";' "$home_nix"; then
  echo "university includeIf should use gitdir:~/Documents/repos/university/"
  exit 1
fi

if ! grep -Fq 'path = "~/.config/git/config-university";' "$home_nix"; then
  echo "university includeIf should point at ~/.config/git/config-university"
  exit 1
fi

if grep -Fq 'gitdir:~/Documents/repos/personal/' "$home_nix"; then
  echo "personal includeIf should be absorbed into the main git config"
  exit 1
fi

if [ ! -f "$gitconfig_university" ]; then
  echo "config-university should exist"
  exit 1
fi
