#!/bin/sh

set -eu
repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
mkdir -p "$tmp/scripts" "$tmp/bin" "$tmp/home"
cp "$repo_root/scripts/common/setup-user.sh" "$tmp/scripts/setup-user.sh"
export DOTFILES_TEST_LOG="$tmp/log" DOTFILES_TEST_NODE_VERSION=v24.16.0
export DOTFILES_TEST_MISE_STATUS=0
for tool in mise nvim; do
  cat >"$tmp/bin/$tool" <<'EOF'
#!/bin/sh
printf '%s:%s\n' "${0##*/}" "$*" >>"$DOTFILES_TEST_LOG"
case "${0##*/}" in mise) exit "$DOTFILES_TEST_MISE_STATUS" ;; esac
EOF
  chmod +x "$tmp/bin/$tool"
done
cat >"$tmp/bin/node" <<'EOF'
#!/bin/sh
echo "$DOTFILES_TEST_NODE_VERSION"
EOF
chmod +x "$tmp/bin/node"
cp "$tmp/bin/node" "$tmp/bin/npm"
for script in install-rustup.sh install-claude-code.sh; do
  cat >"$tmp/scripts/$script" <<'EOF'
#!/bin/sh
echo "${0##*/}" >>"$DOTFILES_TEST_LOG"
EOF
  chmod +x "$tmp/scripts/$script"
done

HOME="$tmp/home" PATH="$tmp/bin:/usr/bin:/bin" sh "$tmp/scripts/setup-user.sh"
expected="mise:install --cd $tmp/home
install-rustup.sh
install-claude-code.sh
nvim:--headless +Lazy! restore +qa"
test "$(cat "$DOTFILES_TEST_LOG")" = "$expected"

: >"$DOTFILES_TEST_LOG"
export DOTFILES_TEST_NODE_VERSION=v22.0.0
if HOME="$tmp/home" PATH="$tmp/bin:/usr/bin:/bin" sh "$tmp/scripts/setup-user.sh" 2>"$tmp/error"; then
  echo "Project Node overrides must stop global setup" >&2
  exit 1
fi
test ! -s "$DOTFILES_TEST_LOG"

export DOTFILES_TEST_NODE_VERSION=v24.16.0 DOTFILES_TEST_MISE_STATUS=7
if HOME="$tmp/home" PATH="$tmp/bin:/usr/bin:/bin" sh "$tmp/scripts/setup-user.sh"; then
  echo "Runtime install failure must stop later installers" >&2
  exit 1
fi
test "$(cat "$DOTFILES_TEST_LOG")" = "mise:install --cd $tmp/home"
echo "Common user setup tests passed"
