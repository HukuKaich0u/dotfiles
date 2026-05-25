#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/install-ghostty-linux.sh

Install Ghostty on Ubuntu using the installer documented by Ghostty.
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

require_supported_distro() {
  if [ ! -r /etc/os-release ]; then
    echo "Unsupported Linux distribution: /etc/os-release not found" >&2
    exit 1
  fi

  . /etc/os-release

  case "${ID:-}" in
    ubuntu)
      :
      ;;
    *)
      echo "Unsupported Linux distribution: ${ID:-unknown}. This script supports Ubuntu only." >&2
      exit 1
      ;;
  esac
}

main() {
  if [ "$#" -ne 0 ]; then
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "install-ghostty-linux.sh does not accept arguments" >&2
        usage >&2
        exit 1
        ;;
    esac
  fi

  if command -v ghostty >/dev/null 2>&1; then
    echo "ghostty already installed, skipping"
    exit 0
  fi

  require_command curl \
    "curl is required before installing Ghostty. Install curl first, then rerun this script."
  require_supported_distro

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
}

main "$@"
