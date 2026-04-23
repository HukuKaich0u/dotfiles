#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
gitconfig="$repo_root/.gitconfig"

if ! grep -Fq '[includeIf "gitdir:~/Documents/repos/personal/"]' "$gitconfig"; then
  echo "personal includeIf should use ~/Documents/repos/personal/"
  exit 1
fi

if ! grep -Fq '[includeIf "gitdir:~/Documents/repos/university/"]' "$gitconfig"; then
  echo "university includeIf should use ~/Documents/repos/university/"
  exit 1
fi
