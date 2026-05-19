#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
WITH_DOCKER=0

usage() {
  cat <<'EOF'
Usage: ./scripts/setup-linux.sh [--with-docker]

Bootstraps a Linux machine for this dotfiles repo by:
  1. Installing core apt packages
  2. Installing rustup
  3. Linking dotfiles

Options:
  --with-docker  Also install the linux-extra Docker profile
EOF
}

main() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --with-docker)
        WITH_DOCKER=1
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "Unknown option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
    shift
  done

  # Keep this script as the single entrypoint only; concrete install behavior
  # lives in the delegated scripts so each step stays re-runnable on its own.
  "$SCRIPT_DIR"/install-linux-packages.sh core
  if [ "$WITH_DOCKER" -eq 1 ]; then
    "$SCRIPT_DIR"/install-linux-packages.sh linux-extra
  fi
  "$SCRIPT_DIR"/install-rustup.sh
  "$SCRIPT_DIR"/link-dotfiles.sh
}

main "$@"
