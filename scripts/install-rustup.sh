#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/install-rustup.sh

Install rustup for the current user if it is not already available.
EOF
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

  installer="$(mktemp "${TMPDIR:-/tmp}/rustup-init.XXXXXX")"
  trap 'rm -f "$installer"' EXIT HUP INT TERM

  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o "$installer"
  sh "$installer" -y
}

main "$@"
