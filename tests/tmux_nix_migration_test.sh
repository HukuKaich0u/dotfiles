#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
tmux_nix_conf="$repo_root/.config/nix/home-manager/tmux/tmux.conf"

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

if [ ! -f "$tmux_nix_conf" ]; then
    echo "tmux nix config file should exist"
    exit 1
fi

assert_contains "$home_nix" "programs.tmux = {" \
    "home-manager should define tmux settings"
assert_contains "$home_nix" "enable = true;" \
    "home-manager should enable tmux"
assert_contains "$home_nix" "sensibleOnTop = false;" \
    "home-manager should not inject tmux-sensible defaults"
assert_contains "$home_nix" "plugins = with pkgs.tmuxPlugins; [" \
    "home-manager should declare tmux plugins through programs.tmux.plugins"
assert_contains "$home_nix" "builtins.readFile ./tmux/tmux.conf" \
    "home-manager should read tmux config from nix-managed file"
assert_contains "$home_nix" "catppuccin" \
    "home-manager should source tmux plugins from nixpkgs"
assert_not_contains "$home_nix" "builtins.replaceStrings" \
    "home-manager should not inject tmux plugin paths manually"

assert_contains "$tmux_nix_conf" "@sessionx-bind 'o'" \
    "tmux config should keep sessionx settings"
assert_contains "$tmux_nix_conf" "@catppuccin_flavor 'macchiato'" \
    "tmux config should keep catppuccin settings"
assert_contains "$tmux_nix_conf" "setw -g pane-border-lines heavy" \
    "tmux config should use heavy pane border lines"
assert_contains "$tmux_nix_conf" "setw -g pane-active-border-style \"fg=#{@thm_yellow},bold\"" \
    "tmux config should strongly highlight the active pane border"
assert_not_contains "$tmux_nix_conf" "@plugin '" \
    "tmux nix config should not declare plugins through TPM syntax"
assert_not_contains "$tmux_nix_conf" "__TMUX_PLUGIN_" \
    "tmux config should not keep nix plugin placeholders once plugins are managed by Home Manager"
assert_not_contains "$tmux_nix_conf" "TMUX_PLUGIN_MANAGER_PATH" \
    "tmux nix config should not keep TPM path"
assert_not_contains "$tmux_nix_conf" "run '~/.config/tmux/plugins/tpm/tpm'" \
    "tmux nix config should not bootstrap TPM"
assert_not_contains "$tmux_nix_conf" "~/.config/tmux/plugins/tmux-resurrect/scripts/save.sh" \
    "tmux nix config should not hardcode resurrect script under ~/.config/tmux/plugins"
assert_not_contains "$tmux_nix_conf" "run-shell __TMUX_PLUGIN_" \
    "tmux config should not load plugins manually once Home Manager owns plugin loading"

echo "tmux nix migration tests passed"
