#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
ghostty_nix="$repo_root/nix/modules/home/programs/ghostty.nix"
ghostty_dir="$repo_root/nix/modules/home/assets/ghostty"
home_default_nix="$repo_root/nix/modules/home/default.nix"
install_sh="$repo_root/scripts/link-dotfiles.sh"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"

  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_not_exists() {
  path="$1"
  message="$2"

  if [ -e "$path" ] || [ -L "$path" ]; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$home_default_nix" './programs/ghostty.nix' \
  "modules/home/default.nix should import programs/ghostty.nix"

if [ ! -f "$ghostty_nix" ]; then
  echo "ghostty.nix should exist"
  exit 1
fi

if [ ! -f "$ghostty_dir/config.ghostty" ]; then
  echo "home-manager ghostty config should exist"
  exit 1
fi

assert_contains "$ghostty_nix" 'Library/Application Support/com.mitchellh.ghostty/config".source = ghosttyConfig;' \
  "ghostty.nix should manage macOS Ghostty config in Application Support"
assert_contains "$ghostty_nix" 'xdg.configFile = lib.mkIf (!pkgs.stdenv.isDarwin)' \
  "ghostty.nix should keep XDG Ghostty config for Linux"
assert_contains "$ghostty_nix" 'ghostty/config.ghostty".source = ghosttyConfig;' \
  "ghostty.nix should source the Linux XDG config from the same asset"
assert_contains "$ghostty_nix" 'ghosttyConfig = ../assets/ghostty/config.ghostty;' \
  "ghostty.nix should source config from the assets tree"
assert_contains "$install_sh" 'SKIP_CONFIG_DIRS="tmux zsh starship.toml yazi bacon wezterm ghostty nvim"' \
  "link-dotfiles.sh should skip ghostty after the home-manager migration"
assert_contains "$ghostty_dir/config.ghostty" 'font-family = "JetBrainsMono Nerd Font"' \
  "ghostty config should carry over the primary WezTerm font"
assert_contains "$ghostty_dir/config.ghostty" 'background-opacity = 0.9' \
  "ghostty config should use the updated opacity baseline"
assert_contains "$ghostty_dir/config.ghostty" 'keybind = ctrl+@=text:\x1b' \
  "ghostty config should map JIS Ctrl-@ to Escape for terminal apps such as Neovim"
assert_contains "$ghostty_dir/config.ghostty" 'keybind = ctrl+q>shift+h=new_split:left' \
  "ghostty config should map WezTerm-style split creation onto Ghostty"
assert_contains "$ghostty_dir/config.ghostty" 'keybind = ctrl+q>h=goto_split:left' \
  "ghostty config should map WezTerm-style split navigation onto Ghostty"
assert_not_exists "$repo_root/.config/ghostty/config.ghostty" \
  "legacy ghostty config.ghostty should not exist in the symlink-managed config tree"
assert_not_exists "$repo_root/.config/ghostty/config" \
  "legacy ghostty config should not exist in the symlink-managed config tree"

echo "ghostty home-manager migration test passed"
