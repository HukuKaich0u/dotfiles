#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/install-homebrew.sh

Install Homebrew on macOS if it is not already available.
EOF
}

main() {
  if [ "$#" -ne 0 ]; then
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "install-homebrew.sh does not accept arguments" >&2
        usage >&2
        exit 1
        ;;
    esac
  fi

  if [ "$(uname -s)" != "Darwin" ]; then
    echo "install-homebrew.sh only supports macOS" >&2
    exit 1
  fi

  if command -v brew >/dev/null 2>&1; then
    echo "brew already installed, skipping"
    exit 0
  fi

  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

main "$@"
