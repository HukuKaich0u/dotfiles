#!/bin/sh

set -eu

# Dotfiles installer
# Links explicitly listed repo files into $HOME, cleans up legacy links,
# and compiles terminfo entries. Everything under ~/.config is owned by
# Home Manager, not this script.

DOTFILES_DIR="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
TERMINFO_SOURCE_DIR="$DOTFILES_DIR/terminfo"

# One "relative-source:absolute-target" pair per line.
EXPLICIT_LINKS="
.apm/apm.yml:$HOME/.apm/apm.yml
"

link_path() {
  source_path="$1"
  target="$2"
  label="$3"

  if [ ! -e "$source_path" ]; then
    echo "✗ $label not found in dotfiles"
    return
  fi

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    current_target="$(readlink "$target")"
    if [ "$current_target" = "$source_path" ]; then
      echo "✓ $label (already linked)"
      return
    fi

    echo "⚠ $label points to $current_target, relinking"
    rm "$target"
    ln -s "$source_path" "$target"
    echo "✓ $label relinked"
    return
  fi

  if [ -e "$target" ]; then
    echo "⚠ $label exists, backing up to ${target}.backup"
    mv "$target" "${target}.backup"
  fi

  ln -s "$source_path" "$target"
  echo "✓ $label linked"
}

install_explicit_links() {
  printf '%s\n' "$EXPLICIT_LINKS" | while IFS= read -r entry; do
    [ -n "$entry" ] || continue
    relative_source="${entry%%:*}"
    target="${entry#*:}"
    link_path "$DOTFILES_DIR/$relative_source" "$target" "$relative_source"
  done
}

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
  install_explicit_links
  compile_terminfo

  echo ""
  echo "Done!"
}

main "$@"
