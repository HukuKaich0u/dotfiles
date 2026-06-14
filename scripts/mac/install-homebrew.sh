#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/mac/install-homebrew.sh

Install Homebrew on macOS if it is not already available.
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

  require_command curl \
    "curl is required before installing Homebrew. Install curl first, then rerun this script."

  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

main "$@"
