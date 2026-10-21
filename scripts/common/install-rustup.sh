#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/common/install-rustup.sh

Install rustup for the current user if it is not already available.
The stable toolchain also gets rust-analyzer and rust-src for editor and
Claude Code language server support. The nightly toolchain is installed
when it is missing.
EOF
}

require_command() {
  command_name="$1"
  message="$2"

  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "$message" >&2
    exit 1
  fi
}

rustup_path() {
  if command -v rustup >/dev/null 2>&1; then
    command -v rustup
    return 0
  fi

  if [ -x "$HOME/.cargo/bin/rustup" ]; then
    echo "$HOME/.cargo/bin/rustup"
    return 0
  fi

  return 1
}

install_rustup() {
  require_command curl \
    "curl is required before installing rustup. Install curl first, then rerun this script."

  installer="$(mktemp "${TMPDIR:-/tmp}/rustup-init.XXXXXX")"
  trap 'rm -f "$installer"' EXIT HUP INT TERM

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$installer"
  sh "$installer" -y --component rust-analyzer --component rust-src
}

# 既存の nightly は更新せず、未導入のときだけ入れる。
install_nightly() {
  rustup="$1"

  # nightly-2026-01-01-... のような日付固定の toolchain は nightly channel とみなさない。
  if "$rustup" toolchain list | grep -q '^nightly-[^0-9]'; then
    echo "nightly toolchain already installed, skipping"
    return 0
  fi

  # その日の nightly に default profile の component が欠けていても入るように、
  # component がそろう日付まで戻ることを許す。
  "$rustup" toolchain install nightly --profile default --allow-downgrade
}

main() {
  installer=""

  if [ "$#" -ne 0 ]; then
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "install-rustup.sh does not accept arguments" >&2
        usage >&2
        exit 1
        ;;
    esac
  fi

  if rustup_path >/dev/null; then
    echo "rustup already installed, skipping"
  else
    install_rustup
  fi

  if ! rustup="$(rustup_path)"; then
    echo "rustup was not found after installation." >&2
    exit 1
  fi

  install_nightly "$rustup"
}

main "$@"
