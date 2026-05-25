#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_default_nix="$repo_root/nix/modules/home/default.nix"
home_packages_nix="$repo_root/nix/modules/home/packages.nix"
darwin_packages_nix="$repo_root/nix/modules/darwin/packages.nix"
nvim_nix="$repo_root/nix/modules/home/programs/nvim.nix"
install_sh="$repo_root/scripts/link-dotfiles.sh"
rustowl_lua="$repo_root/nix/modules/home/assets/nvim/lua/Sethy/plugins/lsp/rustowl.lua"
image_support_lua="$repo_root/nix/modules/home/assets/nvim/lua/Sethy/plugins/image-support.lua"
snacks_lua="$repo_root/nix/modules/home/assets/nvim/lua/Sethy/plugins/snacks.lua"

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

assert_contains "$home_default_nix" './programs/nvim.nix' \
  "modules/home/default.nix should import programs/nvim.nix"

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
assert_contains "$nvim_nix" 'source = ../assets/nvim;' \
  "nvim.nix should source the nvim directory from the assets tree"
assert_not_exists "$repo_root/nix/modules/home/assets/nvim/lazy-lock.json" \
  "nvim assets should not ship a repo-managed lazy-lock.json once lazy writes runtime state"
assert_contains "$home_default_nix" './packages.nix' \
  "modules/home/default.nix should import packages.nix"
assert_contains "$home_packages_nix" 'home.packages = with pkgs; [' \
  "modules/home/packages.nix should manage shared CLI packages"
assert_contains "$home_packages_nix" 'with pkgs; [' \
  "modules/home/packages.nix should use the shared pkgs scope for CLI packages"
assert_contains "$home_packages_nix" 'git' \
  "modules/home/packages.nix should include git as a shared CLI dependency"
assert_contains "$home_packages_nix" 'ripgrep' \
  "modules/home/packages.nix should include ripgrep as a shared CLI dependency"
assert_contains "$home_packages_nix" 'fd' \
  "modules/home/packages.nix should include fd as a shared CLI dependency"
assert_contains "$home_packages_nix" 'gnumake' \
  "modules/home/packages.nix should include gnumake as a shared CLI dependency"
assert_contains "$home_packages_nix" 'tmux' \
  "modules/home/packages.nix should include tmux as a shared CLI dependency"
assert_contains "$home_packages_nix" 'lazygit' \
  "modules/home/packages.nix should include lazygit as a shared CLI dependency"
assert_contains "$home_packages_nix" 'imagemagick' \
  "modules/home/packages.nix should include imagemagick as a shared CLI dependency"
assert_contains "$home_packages_nix" 'bat' \
  "modules/home/packages.nix should include bat as a shared CLI dependency"
assert_contains "$home_packages_nix" 'fzf' \
  "modules/home/packages.nix should include fzf as a shared CLI dependency"
assert_contains "$home_packages_nix" 'postgresql_17' \
  "modules/home/packages.nix should include postgresql_17 as a shared CLI dependency"
assert_contains "$darwin_packages_nix" 'home.packages = with pkgs; [' \
  "modules/darwin/packages.nix should manage darwin-only CLI packages"
assert_contains "$darwin_packages_nix" 'pngpaste' \
  "modules/darwin/packages.nix should include pngpaste as a darwin-only CLI dependency"
assert_contains "$darwin_packages_nix" 'pkgs."ascii-image-converter"' \
  "modules/darwin/packages.nix should include ascii-image-converter as a darwin-only CLI dependency"
assert_contains "$install_sh" 'SKIP_CONFIG_DIRS="tmux zsh starship.toml yazi bacon wezterm ghostty nvim"' \
  "link-dotfiles.sh should skip nvim after the home-manager migration"
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
