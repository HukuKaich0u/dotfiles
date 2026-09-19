#!/bin/sh

set -eu

# Dotfiles installer
# Cleans up legacy links and compiles terminfo entries. Configuration files
# are distributed by Home Manager.

DOTFILES_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
TERMINFO_SOURCE_DIR="$DOTFILES_DIR/terminfo"

cleanup_legacy_nix_link() {
  target="$HOME/.config/nix"

  if [ ! -L "$target" ]; then
    return
  fi

  case "$(readlink "$target")" in
    "$DOTFILES_DIR/.config/nix")
      rm "$target"
      echo "✓ removed legacy nix link $target"
      ;;
  esac
}

compile_terminfo() {
  if [ ! -d "$TERMINFO_SOURCE_DIR" ]; then
    return
  fi

  if ! command -v tic >/dev/null 2>&1; then
    echo "✗ tic not found, skipping terminfo compile" >&2
    return
  fi

  mkdir -p "$HOME/.terminfo"

  for terminfo_src in "$TERMINFO_SOURCE_DIR"/*.src; do
    [ -f "$terminfo_src" ] || continue
    tic -x -o "$HOME/.terminfo" "$terminfo_src"
    echo "✓ terminfo $(basename "$terminfo_src" .src) compiled"
  done
}

main() {
  echo "Installing dotfiles from $DOTFILES_DIR"
  echo ""

  cleanup_legacy_nix_link
  compile_terminfo

  echo ""
  echo "Done!"
}

main "$@"
