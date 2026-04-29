#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
git_nix="$repo_root/.config/nix/home-manager/git.nix"
gitconfig_university="$repo_root/.config/nix/home-manager/git/config-university"

if ! grep -Fq './git.nix' "$home_nix"; then
  echo "home.nix should import git.nix"
  exit 1
fi

if ! grep -Fq 'programs.git = {' "$git_nix"; then
  echo "git.nix should configure git through programs.git"
  exit 1
fi

if grep -Fq 'programs.gh = {' "$git_nix"; then
  echo "git.nix should no longer configure gh"
  exit 1
fi

if ! grep -Fq 'condition = "gitdir:~/Documents/repos/university/";' "$git_nix"; then
  echo "university includeIf should use gitdir:~/Documents/repos/university/"
  exit 1
fi

if ! grep -Fq 'path = "~/.config/git/config-university";' "$git_nix"; then
  echo "university includeIf should point at ~/.config/git/config-university"
  exit 1
fi

if grep -Fq 'gitdir:~/Documents/repos/personal/' "$git_nix"; then
  echo "personal includeIf should be absorbed into the main git config"
  exit 1
fi

if [ ! -f "$gitconfig_university" ]; then
  echo "config-university should exist"
  exit 1
fi

if grep -Fq '/opt/homebrew/bin/gh auth git-credential' "$git_nix"; then
  echo "git config should not hardcode the Homebrew gh path"
  exit 1
fi
