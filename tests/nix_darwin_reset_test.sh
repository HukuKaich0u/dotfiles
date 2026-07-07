#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
config_nix="$repo_root/nix/modules/darwin/system.nix"
home_manager_nix="$repo_root/nix/modules/darwin/home-manager.nix"
homebrew_nix="$repo_root/nix/modules/darwin/homebrew.nix"

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

assert_contains "$config_nix" 'system.stateVersion = 6;' \
  "configuration.nix must keep system.stateVersion"
assert_contains "$config_nix" 'system.configurationRevision = self.rev or self.dirtyRev or null;' \
  "configuration.nix must keep system.configurationRevision"
assert_contains "$config_nix" 'system.primaryUser = "KokiAoyagi";' \
  "configuration.nix must keep system.primaryUser"
assert_contains "$config_nix" 'users.users.KokiAoyagi.home = "/Users/KokiAoyagi";' \
  "configuration.nix must keep the user home path"
assert_contains "$config_nix" './home-manager.nix' \
  "system.nix must keep the home-manager import"
assert_contains "$config_nix" './homebrew.nix' \
  "configuration.nix must import the homebrew bootstrap module"

assert_contains "$config_nix" '../../lib/nixpkgs.nix' \
  "system.nix must keep the shared nixpkgs import"
assert_not_contains "$config_nix" 'nix.enable = false;' \
  "configuration.nix must remove nix.enable"
assert_not_contains "$config_nix" 'system.defaults =' \
  "configuration.nix must remove macOS defaults"
assert_not_contains "$config_nix" 'nixpkgs.hostPlatform' \
  "configuration.nix must remove hostPlatform"
assert_not_contains "$config_nix" 'security.pam.services.sudo_local.touchIdAuth' \
  "configuration.nix must remove Touch ID sudo config"

assert_contains "$home_manager_nix" 'home-manager.users."KokiAoyagi" = ./default.nix;' \
  "home-manager.nix must stay wired to ./default.nix"

if [ ! -f "$homebrew_nix" ]; then
  echo "homebrew.nix must exist"
  exit 1
fi

assert_contains "$homebrew_nix" 'homebrew = {' \
  "homebrew.nix must define the Homebrew attrset"
assert_contains "$homebrew_nix" 'enable = true;' \
  "homebrew.nix must enable Homebrew through nix-darwin"
assert_contains "$homebrew_nix" 'onActivation.cleanup = "uninstall";' \
  "homebrew.nix must uninstall Homebrew packages removed from nix-darwin"
assert_contains "$homebrew_nix" 'onActivation.extraFlags = [ "--force-cleanup" ];' \
  "homebrew.nix must force Homebrew Bundle cleanup during nix-darwin activation"
assert_contains "$homebrew_nix" 'taps = [' \
  "homebrew.nix must declare Homebrew taps"
assert_contains "$homebrew_nix" 'brews = [' \
  "homebrew.nix must declare Homebrew formulae"
assert_contains "$homebrew_nix" 'casks = [' \
  "homebrew.nix must declare Homebrew casks"

expected_taps='
steipete/tap
'

expected_brews='
aom
awscli
dnsmasq
gauche
gcc
git-gui
glib
gnu-time
herdr
jpeg-xl
libheif
liblqr
libraw
libtiff
llvm
marp-cli
php
prek
qemu
terminal-notifier
'

expected_casks='
codex
cmux
drawio
gcloud-cli
github
ngrok
utm
visual-studio-code
wezterm@nightly
'

for tap in $expected_taps; do
  assert_contains "$homebrew_nix" "\"$tap\"" \
    "homebrew.nix must declare tap $tap"
done

for formula in $expected_brews; do
  assert_contains "$homebrew_nix" "\"$formula\"" \
    "homebrew.nix must declare formula $formula"
done

for cask in $expected_casks; do
  assert_contains "$homebrew_nix" "\"$cask\"" \
    "homebrew.nix must declare cask $cask"
done

assert_not_contains "$homebrew_nix" '"cursor-cli"' \
  "homebrew.nix should no longer declare cursor-cli"

echo "nix-darwin reset test passed"
