#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
COMMON_DIR="$(CDPATH= cd -- "$SCRIPT_DIR/../common" && pwd)"

usage() {
  cat <<'EOF'
Usage: ./scripts/mac/setup.sh

Bootstraps a macOS machine for this dotfiles repo by:
  1. Installing Homebrew if needed
  2. Applying nix-darwin
  3. Linking dotfiles
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
        echo "setup-mac.sh does not accept arguments" >&2
        usage >&2
        exit 1
        ;;
    esac
  fi

  "$SCRIPT_DIR"/install-homebrew.sh
  "$SCRIPT_DIR"/apply-nix-darwin.sh
  "$COMMON_DIR"/link-dotfiles.sh
}

main "$@"
