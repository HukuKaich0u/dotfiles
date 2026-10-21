#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"

if [ "$#" -ne 0 ]; then
  echo "Usage: ./scripts/common/setup-user.sh" >&2
  exit 1
fi

for tool in node npm mise nvim; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "$tool is required. Apply Home Manager and open a new shell first." >&2
    exit 1
  fi
done

case "$(node --version)" in
  v24.*) ;;
  *)
    echo "Node.js 24 is required. Run this script outside project runtime overrides." >&2
    exit 1
    ;;
esac

# Project config による runtime の追加を避け、管理対象の global config だけを使う。
mise install --cd "$HOME"
"$SCRIPT_DIR/install-rustup.sh"
"$SCRIPT_DIR/install-claude-code.sh"
nvim --headless '+Lazy! restore' +qa
