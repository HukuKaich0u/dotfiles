# Login-shell entrypoint for repository-managed zsh config.
source "${${(%):-%N}:A:h}/homebrew.zsh"
. "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
