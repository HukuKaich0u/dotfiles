#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/nix/home-manager/home.nix"
nvim_nix="$repo_root/nix/home-manager/nvim.nix"
install_sh="$repo_root/install.sh"
rustowl_lua="$repo_root/nix/home-manager/nvim/lua/Sethy/plugins/lsp/rustowl.lua"
image_support_lua="$repo_root/nix/home-manager/nvim/lua/Sethy/plugins/image-support.lua"
snacks_lua="$repo_root/nix/home-manager/nvim/lua/Sethy/plugins/snacks.lua"

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

assert_contains "$home_nix" './nvim.nix' \
  "home-manager should import nvim.nix"

if [ ! -f "$nvim_nix" ]; then
  echo "nvim.nix should exist"
  exit 1
fi

assert_contains "$nvim_nix" 'programs.neovim = {' \
  "nvim.nix should configure programs.neovim"
assert_contains "$nvim_nix" 'enable = true;' \
  "nvim.nix should enable neovim through Home Manager"
assert_contains "$nvim_nix" 'xdg.configFile."nvim"' \
  "nvim.nix should manage the nvim config directory through xdg.configFile"
assert_contains "$nvim_nix" 'source = ./nvim;' \
  "nvim.nix should source the nvim directory from the home-manager tree"
assert_contains "$home_nix" 'home.packages = with pkgs; [' \
  "home.nix should manage shared CLI packages"
assert_contains "$home_nix" 'with pkgs; [' \
  "home.nix should use the shared pkgs scope for CLI packages"
assert_contains "$home_nix" 'git' \
  "home.nix should include git as a shared CLI dependency"
assert_contains "$home_nix" 'ripgrep' \
  "home.nix should include ripgrep as a shared CLI dependency"
assert_contains "$home_nix" 'fd' \
  "home.nix should include fd as a shared CLI dependency"
assert_contains "$home_nix" 'gnumake' \
  "home.nix should include gnumake as a shared CLI dependency"
assert_contains "$home_nix" 'tmux' \
  "home.nix should include tmux as a shared CLI dependency"
assert_contains "$home_nix" 'lazygit' \
  "home.nix should include lazygit as a shared CLI dependency"
assert_contains "$home_nix" 'imagemagick' \
  "home.nix should include imagemagick as a shared CLI dependency"
assert_contains "$home_nix" 'pngpaste' \
  "home.nix should include pngpaste as a shared CLI dependency"
assert_contains "$home_nix" 'asciiImageConverter = pkgs."ascii-image-converter";' \
  "home.nix should bind ascii-image-converter through a local alias"
assert_contains "$home_nix" 'asciiImageConverter' \
  "home.nix should include ascii-image-converter as a shared CLI dependency"
assert_contains "$install_sh" 'SKIP_CONFIG_DIRS="tmux zsh starship.toml yazi bacon wezterm nvim"' \
  "install.sh should skip nvim after the home-manager migration"
assert_contains "$rustowl_lua" 'enabled = false' \
  "rustowl should be disabled during the Phase 1 Home Manager migration"
assert_contains "$image_support_lua" '"3rd/image.nvim"' \
  "image-support.lua should keep the image.nvim plugin entry for future follow-up"
assert_contains "$image_support_lua" 'enabled = false' \
  "image.nvim should be disabled during the Phase 1 Home Manager migration"
assert_contains "$snacks_lua" 'enabled = false' \
  "snacks image integration should be disabled during the Phase 1 Home Manager migration"
assert_not_exists "$repo_root/.config/nvim" \
  "legacy nvim config should be removed from the symlink-managed config tree"

echo "nvim home-manager migration test passed"
