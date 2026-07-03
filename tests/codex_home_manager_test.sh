#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
codex_nix="$repo_root/nix/modules/home/programs/codex/config.nix"

assert_contains() {
    file="$1"
    pattern="$2"
    message="$3"

    if ! grep -Fq "$pattern" "$file"; then
        echo "$message"
        exit 1
    fi
}

assert_not_contains() {
    file="$1"
    pattern="$2"
    message="$3"

    if grep -Fq "$pattern" "$file"; then
        echo "$message"
        exit 1
    fi
}

if ! nix-instantiate --parse "$codex_nix" >/dev/null; then
    echo "codex config module should parse as valid Nix"
    exit 1
fi

assert_contains "$codex_nix" 'mkdir -p "$HOME/.codex" "$HOME/.codex-work"' \
    "codex config module should create both personal and work Codex homes"
assert_contains "$codex_nix" 'cp --no-preserve=mode,ownership' \
    "codex config module should materialize config.toml from generated settings"
assert_not_contains "$codex_nix" '"AGENTS.md"' \
    "codex config module must not manage ~/AGENTS.md (instruction files are owned by APM)"
assert_not_contains "$codex_nix" 'agentKitSrc' \
    "codex config module must not depend on the agent-kit flake input"

echo "codex home manager tests passed"
