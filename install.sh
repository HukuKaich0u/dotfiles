#!/bin/bash

# Dotfiles installer
# Creates symlinks from ~/.config to this dotfiles directory

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config"

# List of directories to link
DIRS=(
    "nvim"
    "wezterm"
    "git"
    "mise"
)

# List of root-level files to link into $HOME
FILES=(
    ".tmux.conf"
)

echo "Installing dotfiles from $DOTFILES_DIR"
echo ""

mkdir -p "$CONFIG_DIR"

for dir in "${DIRS[@]}"; do
    SOURCE="$DOTFILES_DIR/$dir"
    TARGET="$CONFIG_DIR/$dir"
    
    if [ -e "$SOURCE" ]; then
        if [ -L "$TARGET" ]; then
            echo "✓ $dir (already linked)"
        elif [ -e "$TARGET" ]; then
            echo "⚠ $dir exists, backing up to ${TARGET}.backup"
            mv "$TARGET" "${TARGET}.backup"
            ln -s "$SOURCE" "$TARGET"
            echo "✓ $dir linked"
        else
            ln -s "$SOURCE" "$TARGET"
            echo "✓ $dir linked"
        fi
    else
        echo "✗ $dir not found in dotfiles"
    fi
done

for file in "${FILES[@]}"; do
    SOURCE="$DOTFILES_DIR/$file"
    TARGET="$HOME/$file"

    if [ -e "$SOURCE" ]; then
        if [ -L "$TARGET" ]; then
            echo "✓ $file (already linked)"
        elif [ -e "$TARGET" ]; then
            echo "⚠ $file exists, backing up to ${TARGET}.backup"
            mv "$TARGET" "${TARGET}.backup"
            ln -s "$SOURCE" "$TARGET"
            echo "✓ $file linked"
        else
            ln -s "$SOURCE" "$TARGET"
            echo "✓ $file linked"
        fi
    else
        echo "✗ $file not found in dotfiles"
    fi
done

echo ""
echo "Done!"
