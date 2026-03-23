#!/bin/bash

set -euo pipefail

# Dotfiles installer
# Mirrors repository-managed XDG config directories into ~/.config
# and links selected home directory dotfiles.

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_CONFIG_DIR="$DOTFILES_DIR/.config"
HOME_CONFIG_DIR="$HOME/.config"
HOME_DOTFILES=".zshrc .zprofile"

link_config_dir() {
    local name="$1"
    local source="$REPO_CONFIG_DIR/$name"
    local target="$HOME_CONFIG_DIR/$name"
    local current_target=""

    if [ ! -e "$source" ]; then
        echo "✗ $name not found in dotfiles"
        return
    fi

    if [ -L "$target" ]; then
        current_target="$(readlink "$target")"
        if [ "$current_target" = "$source" ]; then
            echo "✓ $name (already linked)"
            return
        fi

        echo "⚠ $name points to $current_target, relinking"
        rm "$target"
        ln -s "$source" "$target"
        echo "✓ $name relinked"
        return
    fi

    if [ -e "$target" ]; then
        echo "⚠ $name exists, backing up to ${target}.backup"
        mv "$target" "${target}.backup"
    fi

    ln -s "$source" "$target"
    echo "✓ $name linked"
}

link_home_dotfile() {
    local name="$1"
    local source="$DOTFILES_DIR/$name"
    local target="$HOME/$name"
    local current_target=""

    if [ ! -e "$source" ]; then
        echo "✗ $name not found in dotfiles"
        return
    fi

    if [ -L "$target" ]; then
        current_target="$(readlink "$target")"
        if [ "$current_target" = "$source" ]; then
            echo "✓ $name (already linked)"
            return
        fi

        echo "⚠ $name points to $current_target, relinking"
        rm "$target"
        ln -s "$source" "$target"
        echo "✓ $name relinked"
        return
    fi

    if [ -e "$target" ]; then
        echo "⚠ $name exists, backing up to ${target}.backup"
        mv "$target" "${target}.backup"
    fi

    ln -s "$source" "$target"
    echo "✓ $name linked"
}

echo "Installing dotfiles from $DOTFILES_DIR"
echo ""

mkdir -p "$HOME_CONFIG_DIR"

for source in "$REPO_CONFIG_DIR"/*; do
    [ -d "$source" ] || continue
    link_config_dir "$(basename "$source")"
done

for dotfile in $HOME_DOTFILES; do
    link_home_dotfile "$dotfile"
done

echo ""
echo "Done!"
