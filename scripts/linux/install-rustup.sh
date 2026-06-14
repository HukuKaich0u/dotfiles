#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/linux/install-rustup.sh

Install rustup for the current user if it is not already available.
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

rustup_installed() {
  if command -v rustup >/dev/null 2>&1; then
    return 0
  fi

  if [ -x "$HOME/.cargo/bin/rustup" ]; then
    return 0
  fi

  return 1
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

  if rustup_installed; then
    echo "rustup already installed, skipping"
    exit 0
  fi

  require_command curl \
    "curl is required before installing rustup. Install curl first, then rerun this script."

  installer="$(mktemp "${TMPDIR:-/tmp}/rustup-init.XXXXXX")"
  trap 'rm -f "$installer"' EXIT HUP INT TERM

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$installer"
  sh "$installer" -y
}

main "$@"
