#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_default="$repo_root/nix/modules/home/default.nix"
claude_default="$repo_root/nix/modules/home/programs/claude/default.nix"
claude_config="$repo_root/nix/modules/home/programs/claude/config.nix"
darwin_homebrew="$repo_root/nix/modules/darwin/homebrew.nix"
install_script="$repo_root/scripts/install-claude-code.sh"
root_readme="$repo_root/README.md"
scripts_readme="$repo_root/scripts/README.md"
nix_readme="$repo_root/nix/README.md"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"

  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_file_exists() {
  path="$1"
  message="$2"

  if [ ! -e "$path" ]; then
    echo "$message"
    exit 1
  fi
}

assert_file_missing() {
  path="$1"
  message="$2"

  if [ -e "$path" ]; then
    echo "$message"
    exit 1
  fi
}

assert_file_equals() {
  path="$1"
  expected="$2"
  message="$3"

  if [ ! -f "$path" ]; then
    echo "$message"
    exit 1
  fi

  actual="$(cat "$path")"
  if [ "$actual" != "$expected" ]; then
    echo "$message"
    printf 'expected:\n%s\nactual:\n%s\n' "$expected" "$actual"
    exit 1
  fi
}

create_temp_dir() {
  mktemp -d "${TMPDIR:-/tmp}/claude-code-test.XXXXXX"
}

make_executable() {
  chmod +x "$1"
}

test_claude_module_wiring() {
  assert_file_exists "$claude_default" "Claude Home Manager default module must exist"
  assert_file_exists "$claude_config" "Claude Home Manager config module must exist"

  assert_contains "$home_default" './programs/claude' \
    "modules/home/default.nix must import the Claude Home Manager module"
  assert_contains "$claude_default" './config.nix' \
    "Claude Home Manager default module must import config.nix"
  assert_contains "$claude_config" '".claude/CLAUDE.md"' \
    "Claude Home Manager config module must manage ~/.claude/CLAUDE.md"
  assert_contains "$claude_config" 'source = config.lib.file.mkOutOfStoreSymlink "${claudeDotfilesDir}/CLAUDE.md";' \
    "Claude Home Manager config module must point ~/.claude/CLAUDE.md at the repo CLAUDE adapter"
}

test_darwin_homebrew_owns_claude_code() {
  assert_contains "$darwin_homebrew" '"claude-code"' \
    "modules/darwin/homebrew.nix must manage Claude Code via Homebrew cask"
}

test_install_claude_code_requires_npm() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_bin="$tmpdir/bin"
    stderr_log="$tmpdir/stderr.log"
    mkdir -p "$fake_bin"

    if PATH="$fake_bin:/bin:/usr/bin" HOME="$tmpdir/home" /bin/sh "$install_script" 2>"$stderr_log"; then
      echo "install-claude-code.sh should fail when npm is unavailable"
      exit 1
    fi

    assert_contains "$stderr_log" 'npm is required before installing Claude Code' \
      "install-claude-code.sh must explain the npm prerequisite"
  )
}

test_install_claude_code_skips_when_claude_exists() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_bin="$tmpdir/bin"
    npm_log="$tmpdir/npm.log"
    mkdir -p "$fake_bin"

    cat >"$fake_bin/claude" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/claude"

    cat >"$fake_bin/npm" <<EOF
#!/bin/sh
echo "\$*" >>"$npm_log"
exit 0
EOF
    make_executable "$fake_bin/npm"

    PATH="$fake_bin:/bin:/usr/bin" HOME="$tmpdir/home" /bin/sh "$install_script" >/dev/null

    assert_file_missing "$npm_log" "install-claude-code.sh should not invoke npm when claude already exists"
  )
}

test_install_claude_code_runs_npm_global_install() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_bin="$tmpdir/bin"
    home_dir="$tmpdir/home"
    npm_log="$tmpdir/npm.log"
    mkdir -p "$fake_bin" "$home_dir"

    cat >"$fake_bin/npm" <<EOF
#!/bin/sh
echo "\$*" >>"$npm_log"
cat >"$fake_bin/claude" <<'SCRIPT'
#!/bin/sh
exit 0
SCRIPT
chmod +x "$fake_bin/claude"
EOF
    make_executable "$fake_bin/npm"

    PATH="$fake_bin:/bin:/usr/bin" HOME="$home_dir" /bin/sh "$install_script" >/dev/null

    assert_file_equals "$npm_log" 'install -g @anthropic-ai/claude-code' \
      "install-claude-code.sh must install Claude Code with npm -g"
    assert_file_exists "$fake_bin/claude" \
      "install-claude-code.sh must leave a claude command available after installation"
  )
}

test_claude_docs() {
  assert_contains "$root_readme" 'scripts/install-claude-code.sh' \
    "README.md must document the Claude Code installer script"
  assert_contains "$root_readme" 'claude-code' \
    "README.md must mention Claude Code ownership"
  assert_contains "$scripts_readme" 'install-claude-code.sh' \
    "scripts/README.md must describe install-claude-code.sh"
  assert_contains "$nix_readme" 'modules/home/programs/claude/' \
    "nix/README.md must document the Claude Home Manager module"
  assert_contains "$nix_readme" 'claude-code' \
    "nix/README.md must document Claude Code install ownership"
}

test_claude_module_wiring
test_darwin_homebrew_owns_claude_code
test_install_claude_code_requires_npm
test_install_claude_code_skips_when_claude_exists
test_install_claude_code_runs_npm_global_install
test_claude_docs

echo "claude code management test passed"
