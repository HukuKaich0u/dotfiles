#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
git_nix="$repo_root/.config/nix/home-manager/git.nix"

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

if ! grep -Fq 'contents = {' "$git_nix"; then
  echo "university includeIf should inline contents in git.nix"
  exit 1
fi

if grep -Fq 'gitdir:~/Documents/repos/personal/' "$git_nix"; then
  echo "personal includeIf should be absorbed into the main git config"
  exit 1
fi

if ! grep -Fq 'name = "s1f102402697";' "$git_nix"; then
  echo "university includeIf should keep the university git user name"
  exit 1
fi

if ! grep -Fq 'email = "s1f102402697@iniad.org";' "$git_nix"; then
  echo "university includeIf should keep the university git email"
  exit 1
fi

if [ -e "$repo_root/.config/nix/home-manager/git/config-university" ]; then
  echo "config-university should be absorbed into git.nix"
  exit 1
fi

if grep -Fq '/opt/homebrew/bin/gh auth git-credential' "$git_nix"; then
  echo "git config should not hardcode the Homebrew gh path"
  exit 1
fi
