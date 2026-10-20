#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
herdr_repo_only_test="$repo_root/tests/herdr_repo_only_test.nix"

# Herdr は key-bind.md のような repository-only の doc を誤って配布してはならず、
# .config/herdr/config.toml だけを Home Manager でデプロイする。この不変条件を
# flake を実際に評価して検証する。config.toml の中身そのものの照合はしない
# (実装の写経になるだけで回帰を捕まえないため)。
if ! nix eval --impure --file "$herdr_repo_only_test" >/dev/null; then
  echo "Home Manager should deploy only .config/herdr/config.toml and never the repository-only key-bind.md"
  exit 1
fi

# Validate the deployed config with the exact Herdr package used on this host.
# The source derivation runs `herdr config check`, catching schema drift and
# conflicting shortcuts before Home Manager can replace the live config.
case "$(uname -s)" in
  Darwin) herdr_config_target='darwinConfigurations.KokiAoyagi.config.home-manager.users.KokiAoyagi.xdg.configFile."herdr/config.toml".source' ;;
  Linux) herdr_config_target='homeConfigurations.kokiaoyagi.config.xdg.configFile."herdr/config.toml".source' ;;
  *) echo "Unsupported Herdr test platform" >&2; exit 1 ;;
esac
nix build --no-link "$repo_root/nix#$herdr_config_target"

echo "Herdr deploy invariant test passed"
