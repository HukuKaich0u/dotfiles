#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
tmp_home="$(mktemp -d)"
trap 'rm -rf "$tmp_home"' EXIT

mkdir -p "$tmp_home/.config/zsh" "$tmp_home/.local/bin"

output="$(
  env -i \
  HOME="$tmp_home" \
  PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
  XDG_STATE_HOME="$tmp_home/.local/state" \
  ZDOTDIR="$repo_root/.config/nix/home-manager/zsh" \
  zsh -c '
    source "$ZDOTDIR/env.zsh"
    printf "PATH=%s\n" "$PATH"
    printf "HISTFILE=%s\n" "$HISTFILE"
    printf "JAVA_HOME=%s\n" "${JAVA_HOME-}"
    printf "PNPM_HOME=%s\n" "${PNPM_HOME-}"
  '
)"

printf '%s\n' "$output"

if printf '%s' "$output" | grep -q '/Users/KokiAoyagi'; then
  echo "env.zsh leaked machine-specific paths"
  exit 1
fi

if ! printf '%s' "$output" | grep -q "HISTFILE=$tmp_home/.local/state/zsh/.zsh_history"; then
  echo "env.zsh did not relocate HISTFILE under temporary HOME"
  exit 1
fi
