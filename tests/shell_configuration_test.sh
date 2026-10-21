#!/bin/sh

set -eu
repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp/home/.config" "$tmp/cache" "$tmp/home/.local/state"

fixtures="$(DOTFILES_TEST_HOME="$tmp/home" nix build --impure --no-link --print-out-paths \
  --file "$repo_root/tests/shell_configuration_test.nix")"

# 旧 activation の shim だけを除去し、個人の executable / 別の symlink は保持する。
mkdir -p "$tmp/home/.local/bin"
ln -s ../share/mise/installs/node/24.15.0/lib/node_modules/corepack/dist/pnpm.js "$tmp/home/.local/bin/pnpm"
ln -s "$tmp/home/.local/share/mise/installs/node/24.15.0/lib/node_modules/corepack/dist/yarnpkg.js" "$tmp/home/.local/bin/yarnpkg"
ln -s /some/other/pnpx "$tmp/home/.local/bin/pnpx"
printf '#!/bin/sh\nexit 0\n' >"$tmp/home/.local/bin/yarn"
chmod +x "$tmp/home/.local/bin/yarn"
HOME="$tmp/home" "$fixtures/remove-legacy-shims"
test ! -L "$tmp/home/.local/bin/pnpm"
test ! -L "$tmp/home/.local/bin/yarnpkg"
test -L "$tmp/home/.local/bin/pnpx"
test -x "$tmp/home/.local/bin/yarn"

# 実際に生成した rc を、live HOME / shell config に触れずに読み込む。
cd "$tmp/home"
env -i HOME="$tmp/home" USER=shell-test XDG_CONFIG_HOME="$tmp/home/.config" \
  XDG_CACHE_HOME="$tmp/cache" XDG_STATE_HOME="$tmp/home/.local/state" \
  MISE_CONFIG_DIR="$tmp/home/.config/mise" MISE_DATA_DIR="$tmp/home/.local/share/mise" \
  MISE_STATE_DIR="$tmp/home/.local/state/mise" LC_ALL=C \
  NOSYSBASHRC=1 __NIX_DARWIN_SET_ENVIRONMENT_DONE=1 \
  TERM=xterm-256color PATH="$fixtures:/usr/bin:/bin:/usr/sbin:/sbin" DOTFILES_TEST_NODE="$fixtures/node" \
  "$fixtures/bash" --noprofile --rcfile "$fixtures/bashrc" -ic '
    set -eE -o pipefail
    trap '\''printf "Bash check failed at line %s: %s\n" "$LINENO" "$BASH_COMMAND" >&2'\'' ERR
    test "$(alias nv)" = "alias nv='\''nvim'\''"
    type -t yy | grep -qx function
    type -t z | grep -qx function
    type -t _direnv_hook | grep -qx function
    type -t _mise_hook | grep -qx function
    type -t starship_precmd | grep -qx function
    test "$HISTSIZE" = 10000
    test "$HISTFILESIZE" = 10000
    test "$HISTCONTROL" = ignoreboth
    test "$HISTFILE" = "$HOME/.local/state/bash/history"
    shopt -q histappend
    history_after_failure() { false; __dotfiles_history_sync; }
    if history_after_failure; then
      echo "History hook lost the command exit status" >&2
      exit 1
    else
      test "$?" = 1
    fi
    history -s "printf shared-history"
    __dotfiles_history_sync
    grep -q shared-history "$HISTFILE"
    case "$PROMPT_COMMAND ${STARSHIP_PROMPT_COMMAND:-}" in *__dotfiles_history_sync*) ;; *) exit 1 ;; esac
    # 対話 shell の子の非対話 Bash からも常用 Node が見える。
    bash --noprofile --norc -c '\''
      resolved_node="$(command -v node)"
      if [ "$resolved_node" != "$DOTFILES_TEST_NODE" ]; then
        printf "Unexpected Node path: %s (expected %s)\n" "$resolved_node" "$DOTFILES_TEST_NODE" >&2
        exit 1
      fi
      case "$(node --version)" in v24.*) ;; *) exit 1 ;; esac
    '\''
  '

echo "Bash configuration test passed (native host packages)"
