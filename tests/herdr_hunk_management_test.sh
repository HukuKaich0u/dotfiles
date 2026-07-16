#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
flake_nix="$repo_root/nix/flake.nix"
darwin_home_manager_nix="$repo_root/nix/modules/darwin/home-manager.nix"
home_default_nix="$repo_root/nix/modules/home/default.nix"
hunk_nix="$repo_root/nix/modules/home/programs/hunk.nix"
herdr_nix="$repo_root/nix/modules/home/programs/herdr.nix"
herdr_config="$repo_root/nix/modules/home/assets/herdr/config.toml"
herdr_key_bind_doc="$repo_root/nix/modules/home/assets/herdr/key-bind.md"
herdr_config_test="$repo_root/tests/herdr_config_test.nix"
darwin_homebrew_nix="$repo_root/nix/modules/darwin/homebrew.nix"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"

  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_not_contains() {
  file="$1"
  needle="$2"
  message="$3"

  if grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

hunk_input_block="$({
  awk '
    /^[[:space:]]*hunk = \{/ { in_hunk = 1 }
    in_hunk { print }
    in_hunk && /^[[:space:]]*};[[:space:]]*$/ { exit }
  ' "$flake_nix"
})"

if [ -z "$hunk_input_block" ]; then
  echo "nix/flake.nix should declare the Hunk input"
  exit 1
fi

if ! printf '%s\n' "$hunk_input_block" | grep -Fq 'url = "github:modem-dev/hunk";'; then
  echo "the Hunk input should use the official modem-dev/hunk flake"
  exit 1
fi

if ! printf '%s\n' "$hunk_input_block" | grep -Fq 'inputs.nixpkgs.follows = "nixpkgs";'; then
  echo "the Hunk input should follow the shared nixpkgs input"
  exit 1
fi

assert_contains "$flake_nix" 'extraSpecialArgs = {inherit hunk;};' \
  "standalone Home Manager should receive the Hunk flake input"
assert_contains "$flake_nix" 'specialArgs = {inherit self hunk;};' \
  "nix-darwin should receive the self and Hunk flake inputs"
assert_contains "$darwin_home_manager_nix" '{hunk, ...}' \
  "the darwin Home Manager bridge should receive the Hunk flake input"
assert_contains "$darwin_home_manager_nix" 'home-manager.extraSpecialArgs = {inherit hunk;};' \
  "nix-darwin Home Manager users should receive the Hunk flake input"
assert_contains "$home_default_nix" 'hunk.homeManagerModules.default' \
  "the shared Home Manager tree should import Hunk's official module"
assert_contains "$home_default_nix" './programs/hunk.nix' \
  "the shared Home Manager tree should import the Hunk configuration"
assert_contains "$home_default_nix" './programs/herdr.nix' \
  "the shared Home Manager tree should import the Herdr configuration"

if [ ! -f "$hunk_nix" ]; then
  echo "nix/modules/home/programs/hunk.nix should exist"
  exit 1
fi

assert_contains "$hunk_nix" 'programs.hunk = {' \
  "hunk.nix should configure programs.hunk"
assert_contains "$hunk_nix" 'enable = true;' \
  "hunk.nix should enable Hunk"
assert_contains "$hunk_nix" 'enableGitIntegration = false;' \
  "hunk.nix should leave Git integration disabled"
assert_contains "$hunk_nix" 'theme = "auto";' \
  "hunk.nix should use the automatic theme"
assert_contains "$hunk_nix" 'mode = "auto";' \
  "hunk.nix should use automatic mode"
assert_contains "$hunk_nix" 'exclude_untracked = false;' \
  "hunk.nix should include untracked files"
assert_contains "$hunk_nix" 'line_numbers = true;' \
  "hunk.nix should show line numbers"
assert_contains "$hunk_nix" 'wrap_lines = false;' \
  "hunk.nix should not wrap lines"
assert_contains "$hunk_nix" 'menu_bar = true;' \
  "hunk.nix should show the menu bar"
assert_contains "$hunk_nix" 'transparent_background = true;' \
  "hunk.nix should use a transparent background"

if [ ! -f "$herdr_nix" ]; then
  echo "nix/modules/home/programs/herdr.nix should exist"
  exit 1
fi

if [ ! -f "$herdr_config" ]; then
  echo "nix/modules/home/assets/herdr/config.toml should exist"
  exit 1
fi

assert_contains "$herdr_nix" 'xdg.configFile."herdr/config.toml"' \
  "herdr.nix should manage the Herdr configuration through XDG"
assert_contains "$herdr_nix" 'source = ../assets/herdr/config.toml;' \
  "herdr.nix should source the repository-owned Herdr configuration"
assert_contains "$herdr_nix" 'force = true;' \
  "herdr.nix should replace an existing Herdr configuration"
assert_not_contains "$herdr_nix" 'key-bind.md' \
  "herdr.nix should not deploy the repository-only key-binding reference"
assert_not_contains "$herdr_nix" 'source = ../assets/herdr;' \
  "herdr.nix should source only config.toml, not the whole Herdr assets directory"

if [ ! -f "$herdr_key_bind_doc" ]; then
  echo "nix/modules/home/assets/herdr/key-bind.md should exist"
  exit 1
fi

while IFS= read -r key_token; do
  assert_contains "$herdr_key_bind_doc" "$key_token" \
    "Herdr key-binding reference should document: $key_token"
done <<'EOF'
Ctrl-g
prefix+c
prefix+p/n
prefix+1..9
prefix+comma
prefix+ampersand
prefix+h/j/k/l
prefix+Shift+j
prefix+Shift+l
prefix+[
prefix+z
prefix+x
prefix+s
prefix+r
prefix+d
prefix+;
prefix+o
prefix+Shift+9/0
prefix+Shift+4
prefix+Shift+n
prefix+Shift+g
prefix+Shift+d
prefix+g
prefix+b
prefix+Shift+s
prefix+Shift+o
prefix+?
prefix+Shift+h
EOF

while IFS= read -r required_text; do
  assert_contains "$herdr_key_bind_doc" "$required_text" \
    "Herdr key-binding reference should explain: $required_text"
done <<'EOF'
session | workspace
repo/task/investigation switch
window | tab
view inside workspace
pane | pane
independently focused terminal region within a tab
server/socket | session
fully separate persistent runtime
H/K pane split bindings are unused because this setup only creates panes to the right or downward.
< > tab reordering is unassigned because Herdr has no corresponding tab-reordering operation.
All Shift+h/j/k/l pane swaps are disabled because Shift+j/l create splits, Shift+h opens Hunk, and Shift+k is intentionally left without an action.
EOF

while IFS= read -r required_line; do
  assert_contains "$herdr_config" "$required_line" \
    "Herdr config should contain: $required_line"
done <<'EOF'
onboarding = false
[theme]
name = "terminal"
[terminal]
new_cwd = "follow"
[keys]
prefix = "ctrl+g"
help = "prefix+?"
settings = "prefix+shift+s"
detach = "prefix+d"
reload_config = "prefix+r"
open_notification_target = "prefix+shift+o"
workspace_picker = "prefix+o"
goto = "prefix+g"
new_workspace = "prefix+shift+n"
new_worktree = "prefix+shift+g"
rename_workspace = "prefix+shift+4"
close_workspace = "prefix+shift+d"
previous_workspace = "prefix+shift+9"
next_workspace = "prefix+shift+0"
new_tab = "prefix+c"
rename_tab = "prefix+comma"
previous_tab = "prefix+p"
next_tab = "prefix+n"
switch_tab = "prefix+1..9"
close_tab = "prefix+ampersand"
copy_mode = "prefix+["
focus_pane_left = "prefix+h"
focus_pane_down = "prefix+j"
focus_pane_up = "prefix+k"
focus_pane_right = "prefix+l"
swap_pane_left = ""
swap_pane_down = ""
swap_pane_up = ""
swap_pane_right = ""
last_pane = "prefix+;"
split_vertical = "prefix+shift+l"
split_horizontal = "prefix+shift+j"
close_pane = "prefix+x"
zoom = "prefix+z"
resize_mode = "prefix+s"
toggle_sidebar = "prefix+b"
[[keys.command]]
key = "prefix+shift+h"
type = "pane"
command = "hunk diff --watch"
description = "review changes with Hunk"
[ui]
sidebar_width = 30
sidebar_min_width = 18
sidebar_max_width = 36
sidebar_collapsed_mode = "compact"
mouse_capture = true
confirm_close = true
prompt_new_tab_name = true
pane_borders = true
pane_gaps = true
show_agent_labels_on_pane_borders = true
hide_tab_bar_when_single_tab = true
agent_panel_sort = "priority"
[ui.toast]
delivery = "system"
delay_seconds = 1
[ui.sound]
enabled = true
[experimental]
pane_history = false
EOF

assert_contains "$darwin_homebrew_nix" '"herdr"' \
  "nix/modules/darwin/homebrew.nix should continue managing Herdr"
assert_not_contains "$darwin_homebrew_nix" '"hunk"' \
  "nix/modules/darwin/homebrew.nix should not manage the Hunk formula"

if ! nix eval --file "$herdr_config_test" >/dev/null; then
  echo "Herdr module and parsed configuration should match the approved structure"
  exit 1
fi

echo "Herdr and Hunk management tests passed"
