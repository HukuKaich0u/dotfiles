#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="${BOOTSTRAP_DOTFILES_DIR:-$(cd "$(dirname "$0")/.." && pwd)}"
OS_RELEASE_FILE="${BOOTSTRAP_OS_RELEASE:-/etc/os-release}"
PACKAGES=(
    git
    curl
    zsh
    tmux
    neovim
    ripgrep
    fd-find
    fzf
    unzip
    build-essential
    nodejs
    npm
)

log() {
    echo "==> $*"
}

fail() {
    echo "Error: $*" >&2
    exit 1
}

require_command() {
    local name="$1"

    command -v "$name" >/dev/null 2>&1 || fail "required command not found: $name"
}

ensure_ubuntu() {
    [ -r "$OS_RELEASE_FILE" ] || fail "this script only supports Ubuntu"

    # shellcheck disable=SC1091
    . "$OS_RELEASE_FILE"

    [ "${ID:-}" = "ubuntu" ] || fail "this script only supports Ubuntu"
}

install_packages() {
    log "updating apt package lists"
    sudo apt update

    log "installing Ubuntu packages"
    sudo apt install -y "${PACKAGES[@]}"
}

install_codex() {
    if command -v codex >/dev/null 2>&1; then
        log "codex already installed"
        return
    fi

    require_command npm

    log "installing Codex CLI"
    npm install -g @openai/codex

    command -v codex >/dev/null 2>&1 || fail "codex install completed but binary is not on PATH"
}

apply_dotfiles() {
    log "applying dotfiles"
    "$DOTFILES_DIR/install.sh"
}

maybe_switch_shell() {
    local zsh_path=""
    zsh_path="$(command -v zsh || true)"

    [ -n "$zsh_path" ] || return

    if [ "${SHELL:-}" = "$zsh_path" ]; then
        return
    fi

    log "attempting to switch login shell to zsh"
    if chsh -s "$zsh_path"; then
        return
    fi

    echo "Run this manually to switch your login shell:"
    echo "chsh -s $zsh_path"
}

print_next_steps() {
    echo
    echo "Bootstrap complete."
    echo "Next steps:"
    echo "  1. Run: codex login"
    echo "  2. Restart your shell or log out and back in"
    echo "  3. Verify: tmux -V"
    echo "  4. Verify: nvim --version"
}

main() {
    ensure_ubuntu
    require_command sudo

    install_packages
    install_codex
    apply_dotfiles
    maybe_switch_shell
    print_next_steps
}

main "$@"
