#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'EOF'
Usage: ./scripts/apply-nix-darwin.sh

Apply the nix-darwin configuration for this repo on macOS.
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
        echo "apply-nix-darwin.sh does not accept arguments" >&2
        usage >&2
        exit 1
        ;;
    esac
  fi

  if [ "$(uname -s)" != "Darwin" ]; then
    echo "apply-nix-darwin.sh only supports macOS" >&2
    exit 1
  fi

  if ! command -v nix >/dev/null 2>&1; then
    echo "nix is required before applying nix-darwin. Install Determinate Nix or the official Nix installer first." >&2
    exit 1
  fi

  if ! command -v darwin-rebuild >/dev/null 2>&1; then
    echo "darwin-rebuild is required before applying nix-darwin. Install nix-darwin first, then rerun this script." >&2
    exit 1
  fi

  cd "$REPO_ROOT"
  darwin-rebuild switch --flake ./nix#KokiAoyagi
}

main "$@"
