#!/bin/bash

set -euo pipefail

# Dotfiles installer
# Mirrors repository-managed XDG config directories into ~/.config
# and links selected home directory dotfiles.

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_CONFIG_DIR="$DOTFILES_DIR/.config"
HOME_CONFIG_DIR="$HOME/.config"
HOME_DOTFILES=".zshenv .zshrc .zprofile"
TERMINFO_SOURCE_DIR="$DOTFILES_DIR/terminfo"
EXPLICIT_LINKS=(
    ".codex/config.toml:$HOME/.codex/config.toml"
    ".codex/AGENTS.md:$HOME/.codex/AGENTS.md"
    ".codex/hooks.json:$HOME/.codex/hooks.json"
    ".codex/hooks:$HOME/.codex/hooks"
    ".claude/settings.json:$HOME/.claude/settings.json"
    ".claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
)

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

ensure_real_directory() {
    local target="$1"

    if [ -L "$target" ]; then
        echo "⚠ $target is a symlink, backing up to ${target}.dirlink.backup"
        mv "$target" "${target}.dirlink.backup"
    elif [ -e "$target" ] && [ ! -d "$target" ]; then
        echo "⚠ $target exists and is not a directory, backing up to ${target}.backup"
        mv "$target" "${target}.backup"
    fi

    mkdir -p "$target"
}

link_directory_children() {
    local source_dir="$1"
    local target_dir="$2"
    local label_prefix="$3"
    local child=""
    local name=""

    if [ ! -d "$source_dir" ]; then
        return
    fi

    ensure_real_directory "$target_dir"

    for child in "$source_dir"/*; do
        if [ ! -e "$child" ]; then
            continue
        fi

        name="$(basename "$child")"
        link_path "$child" "$target_dir/$name" "$label_prefix/$name"
    done
}

install_config_tree() {
    local source=""

    mkdir -p "$HOME_CONFIG_DIR"

    for source in "$REPO_CONFIG_DIR"/*; do
        if [ -d "$source" ]; then
            link_config_dir "$(basename "$source")"
            continue
        fi

        if [ -f "$source" ]; then
            link_config_file "$(basename "$source")"
        fi
    done
}

install_home_dotfiles() {
    local dotfile=""

    for dotfile in $HOME_DOTFILES; do
        link_home_dotfile "$dotfile"
    done
}

install_managed_skill_entries() {
    link_directory_children "$DOTFILES_DIR/.agents/skills" "$HOME/.agents/skills" ".agents/skills"
    link_directory_children "$DOTFILES_DIR/.claude/skills" "$HOME/.claude/skills" ".claude/skills"
}

restore_local_skill_links() {
    if [ -L "$HOME/.agents/skills.backup/superpowers" ] && [ ! -e "$HOME/.agents/skills/superpowers" ]; then
        ln -s "$HOME/.codex/superpowers/skills" "$HOME/.agents/skills/superpowers"
        echo "✓ restored local skill link .agents/skills/superpowers"
    fi
}

mirror_common_skills_to_claude() {
    local source_dir="$HOME/.agents/skills"
    local target_dir="$HOME/.claude/skills"
    local child=""
    local name=""

    ensure_real_directory "$target_dir"

    for child in "$source_dir"/*; do
        if [ ! -e "$child" ]; then
            continue
        fi

        name="$(basename "$child")"
        link_path "$child" "$target_dir/$name" ".claude/skills/$name"
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
install_explicit_links
install_home_dotfiles
install_managed_skill_entries
restore_local_skill_links
mirror_common_skills_to_claude

compile_terminfo "$TERMINFO_SOURCE_DIR"

echo ""
echo "Done!"
