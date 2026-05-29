#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/install-claude-code.sh

Install Claude Code with npm if it is not already available on PATH.
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
        echo "install-claude-code.sh does not accept arguments" >&2
        usage >&2
        exit 1
        ;;
    esac
  fi

  if command -v claude >/dev/null 2>&1; then
    echo "claude already installed, skipping"
    exit 0
  fi

  if ! command -v npm >/dev/null 2>&1; then
    echo "npm is required before installing Claude Code. Run 'mise install' first, then rerun this script." >&2
    exit 1
  fi

  npm install -g @anthropic-ai/claude-code

  if ! command -v claude >/dev/null 2>&1; then
    echo "Claude Code install completed, but 'claude' is still not on PATH. Open a new shell and verify your npm global bin path, then rerun this script." >&2
    exit 1
  fi
}

main "$@"
