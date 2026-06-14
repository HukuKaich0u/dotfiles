#!/bin/bash

set -euo pipefail

# Dotfiles installer
# Mirrors repository-managed XDG config directories into ~/.config
# and links selected home directory dotfiles.

DOTFILES_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
REPO_CONFIG_DIR="$DOTFILES_DIR/.config"
HOME_CONFIG_DIR="$HOME/.config"
HOME_DOTFILES=""
TERMINFO_SOURCE_DIR="$DOTFILES_DIR/terminfo"
EXPLICIT_LINKS=(
    ".agents/AGENTS.md:$HOME/AGENTS.md"
    ".claude/CLAUDE.md:$HOME/CLAUDE.md"
    ".agents/AGENTS.md:$HOME/.agents/AGENTS.md"
    ".agents/skills:$HOME/.agents/skills"
    ".codex/AGENTS.md:$HOME/.codex/AGENTS.md"
    ".claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
)
SKIP_CONFIG_DIRS="tmux zsh starship.toml yazi bacon wezterm ghostty nvim"

ensure_parent_dir() {
    local target="$1"

    mkdir -p "$(dirname "$target")"
}

link_path() {
    local source="$1"
    local target="$2"
    local label="$3"
    local current_target=""

    if [ ! -e "$source" ]; then
        echo "✗ $label not found in dotfiles"
        return
    fi

    ensure_parent_dir "$target"

    if [ -L "$target" ]; then
        current_target="$(readlink "$target")"
        if [ "$current_target" = "$source" ]; then
            echo "✓ $label (already linked)"
            return
        fi

        echo "⚠ $label points to $current_target, relinking"
        rm "$target"
        ln -s "$source" "$target"
        echo "✓ $label relinked"
        return
    fi

    if [ -e "$target" ]; then
        echo "⚠ $label exists, backing up to ${target}.backup"
        mv "$target" "${target}.backup"
    fi

    ln -s "$source" "$target"
    echo "✓ $label linked"
}

link_config_dir() {
    local name="$1"

    link_path "$REPO_CONFIG_DIR/$name" "$HOME_CONFIG_DIR/$name" "$name"
}

link_config_file() {
    local name="$1"

    link_path "$REPO_CONFIG_DIR/$name" "$HOME_CONFIG_DIR/$name" "$name"
}

link_home_dotfile() {
    local name="$1"

    link_path "$DOTFILES_DIR/$name" "$HOME/$name" "$name"
}

install_explicit_links() {
    local entry=""
    local relative_source=""
    local target=""

    for entry in "${EXPLICIT_LINKS[@]}"; do
        relative_source="${entry%%:*}"
        target="${entry#*:}"
        link_path "$DOTFILES_DIR/$relative_source" "$target" "$relative_source"
    done
}

cleanup_legacy_ai_links() {
    local target=""
    local current_target=""

    for target in \
        "$HOME/.claude/skills"
    do
        if [ ! -L "$target" ]; then
            continue
        fi

        current_target="$(readlink "$target")"
        case "$current_target" in
            "$DOTFILES_DIR"/*)
                rm "$target"
                echo "✓ removed legacy AI link $target"
                ;;
        esac
    done
}

cleanup_legacy_nix_link() {
    local target="$HOME/.config/nix"
    local current_target=""

    if [ ! -L "$target" ]; then
        return
    fi

    current_target="$(readlink "$target")"
    case "$current_target" in
        "$DOTFILES_DIR/.config/nix")
            rm "$target"
            echo "✓ removed legacy nix link $target"
            ;;
    esac
}

install_config_tree() {
    local source=""
    local name=""

    mkdir -p "$HOME_CONFIG_DIR"

    for source in "$REPO_CONFIG_DIR"/*; do
        name="$(basename "$source")"

        case " $SKIP_CONFIG_DIRS " in
            *" $name "*)
                continue
                ;;
        esac

        if [ -d "$source" ]; then
            link_config_dir "$name"
            continue
        fi

        if [ -f "$source" ]; then
            link_config_file "$name"
        fi
    done
}

install_home_dotfiles() {
    local dotfile=""

    for dotfile in $HOME_DOTFILES; do
        link_home_dotfile "$dotfile"
    done
}

compile_terminfo() {
    local source_dir="$1"

    if [ ! -d "$source_dir" ]; then
        return
    fi

    mkdir -p "$HOME/.terminfo"

    for source in "$source_dir"/*.src; do
        if [ ! -f "$source" ]; then
            continue
        fi

        tic -x -o "$HOME/.terminfo" "$source"
        echo "✓ terminfo $(basename "$source" .src) compiled"
    done
}

echo "Installing dotfiles from $DOTFILES_DIR"
echo ""

install_config_tree
cleanup_legacy_ai_links
cleanup_legacy_nix_link
install_explicit_links
install_home_dotfiles

compile_terminfo "$TERMINFO_SOURCE_DIR"

echo ""
echo "Done!"
