#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/nix/home-manager/home.nix"
tmux_nix="$repo_root/nix/home-manager/tmux.nix"
tmux_nix_conf="$repo_root/nix/home-manager/tmux/tmux.conf"

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

assert_contains "$home_nix" "./tmux.nix" \
    "home.nix should import tmux.nix"

if [ ! -f "$tmux_nix_conf" ]; then
    echo "tmux nix config file should exist"
    exit 1
fi

assert_contains "$tmux_nix" "programs.tmux = {" \
    "tmux.nix should define tmux settings"
assert_contains "$tmux_nix" "enable = true;" \
    "home-manager should enable tmux"
assert_contains "$tmux_nix" "sensibleOnTop = false;" \
    "home-manager should not inject tmux-sensible defaults"
assert_contains "$tmux_nix" "plugins = with pkgs.tmuxPlugins; [" \
    "home-manager should declare tmux plugins through programs.tmux.plugins"
assert_contains "$tmux_nix" "builtins.readFile ./tmux/tmux.conf" \
    "home-manager should read tmux config from nix-managed file"
assert_contains "$tmux_nix" "catppuccin" \
    "home-manager should source tmux plugins from nixpkgs"
assert_contains "$tmux_nix" "plugin = tmux-sessionx;" \
    "home-manager should configure sessionx through a plugin attrset"
assert_contains "$tmux_nix" "@sessionx-bind 'o'" \
    "sessionx bind should be configured before the plugin loads"
assert_not_contains "$tmux_nix" "builtins.replaceStrings" \
    "home-manager should not inject tmux plugin paths manually"
assert_not_contains "$tmux_nix" "      battery" \
    "battery status should not depend on tmux plugin interpolation order"
assert_not_contains "$tmux_nix" "      online-status" \
    "wifi status should not depend on the online-status tmux plugin"
assert_contains "$tmux_nix" "battery_script=" \
    "tmux.nix should define a direct battery status command"
assert_contains "$tmux_nix" "wifi_status_script=" \
    "tmux.nix should define a direct wifi status command"
assert_contains "$tmux_nix" 'fg=#{@thm_blue}] #(${battery_script}/battery_icon.sh)' \
    "battery status segment should use the blue theme accent"
assert_contains "$tmux_nix" 'fg=#{@thm_blue}] #(${wifi_status_script})' \
    "wifi status segment should use the blue theme accent"
assert_not_contains "$tmux_nix" 'fg=#{@thm_green}] #(${battery_script}/battery_icon.sh)' \
    "battery status segment should no longer use the green accent"
assert_not_contains "$tmux_nix" 'fg=#{@thm_rosewater}] #(${wifi_status_script})' \
    "wifi status segment should no longer use the rosewater accent"
assert_contains "$tmux_nix" "pkgs.writeShellScript" \
    "wifi status should be wrapped in a nix-managed script to keep tmux parsing stable"
assert_not_contains "$tmux_nix" "wifi_status_script=''#(" \
    "wifi status should not inline a shell program directly into tmux config"
assert_contains "$tmux_nix" "nmcli" \
    "linux wifi detection should prefer local wifi state via nmcli when available"
assert_contains "$tmux_nix" "iwgetid" \
    "linux wifi detection should fall back to iwgetid when nmcli is unavailable"
assert_contains "$tmux_nix" "/sys/class/net" \
    "linux wifi detection should inspect kernel network state as a final fallback"
assert_not_contains "$tmux_nix" "elif ping -c 1 -W 3 1.1.1.1" \
    "linux wifi detection should not rely on internet reachability alone"

assert_contains "$tmux_nix_conf" "@catppuccin_flavor 'macchiato'" \
    "tmux config should keep catppuccin settings"
assert_contains "$tmux_nix_conf" "fg=#{@thm_red}" \
    "tmux status-left session segment should use the theme red accent"
assert_not_contains "$tmux_nix_conf" "fg=#{@thm_green}]  #S" \
    "tmux status-left session segment should no longer use the green accent"
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
assert_not_contains "$tmux_nix_conf" "#{battery_icon}" \
    "tmux.conf should not rely on battery plugin placeholders in status-right"
assert_not_contains "$tmux_nix_conf" "#{battery_percentage}" \
    "tmux.conf should not rely on battery plugin placeholders in status-right"
assert_not_contains "$tmux_nix_conf" "#{online_status}" \
    "tmux.conf should not rely on online-status placeholders in status-right"
assert_not_contains "$tmux_nix_conf" "@sessionx-bind 'o'" \
    "sessionx bind should not live in extraConfig after plugin migration"
assert_not_contains "$tmux_nix_conf" "run '~/.config/tmux/plugins/tpm/tpm'" \
    "tmux nix config should not bootstrap TPM"
assert_not_contains "$tmux_nix_conf" "~/.config/tmux/plugins/tmux-resurrect/scripts/save.sh" \
    "tmux nix config should not hardcode resurrect script under ~/.config/tmux/plugins"
assert_not_contains "$tmux_nix_conf" "run-shell __TMUX_PLUGIN_" \
    "tmux config should not load plugins manually once Home Manager owns plugin loading"

echo "tmux nix migration tests passed"
