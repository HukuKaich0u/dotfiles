#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_default="$repo_root/nix/modules/home/default.nix"
claude_default="$repo_root/nix/modules/home/programs/claude/default.nix"
claude_config="$repo_root/nix/modules/home/programs/claude/config.nix"
darwin_homebrew="$repo_root/nix/modules/darwin/homebrew.nix"
install_script="$repo_root/scripts/common/install-claude-code.sh"
root_readme="$repo_root/README.md"
scripts_readme="$repo_root/scripts/README.md"
nix_readme="$repo_root/nix/README.md"
apm_yml="$repo_root/.apm/apm.yml"

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
  assert_contains "$claude_config" 'home.activation.mergeClaudeSettings' \
    "Claude Home Manager config module must merge Claude settings during activation"
  assert_contains "$claude_config" '${pkgs.jq}/bin/jq -S -s' \
    "Claude Home Manager config module must merge JSON via jq"
  assert_not_contains "$claude_config" 'settings = {' \
    "Claude Home Manager config module must not clobber settings.json via programs.claude-code.settings"
  assert_not_contains "$claude_config" '"CLAUDE.md"' \
    "Claude config module must not manage ~/CLAUDE.md (instruction files are owned by APM)"
  assert_not_contains "$claude_config" 'agentKitSrc' \
    "Claude config module must not depend on the agent-kit flake input"
}

test_darwin_homebrew_does_not_own_claude_code() {
  assert_not_contains "$darwin_homebrew" '"claude-code"' \
    "modules/darwin/homebrew.nix must not manage Claude Code via Homebrew cask"
}

test_install_claude_code_requires_curl() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_bin="$tmpdir/bin"
    stderr_log="$tmpdir/stderr.log"
    mkdir -p "$fake_bin"

    cat >"$fake_bin/bash" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/bash"

    if PATH="$fake_bin" HOME="$tmpdir/home" /bin/sh "$install_script" 2>"$stderr_log"; then
      echo "install-claude-code.sh should fail when curl is unavailable"
      exit 1
    fi

    assert_contains "$stderr_log" 'curl is required before installing Claude Code' \
      "install-claude-code.sh must explain the curl prerequisite"
  )
}

test_install_claude_code_requires_bash() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_bin="$tmpdir/bin"
    stderr_log="$tmpdir/stderr.log"
    mkdir -p "$fake_bin"

    cat >"$fake_bin/curl" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/curl"

    if PATH="$fake_bin" HOME="$tmpdir/home" /bin/sh "$install_script" 2>"$stderr_log"; then
      echo "install-claude-code.sh should fail when bash is unavailable"
      exit 1
    fi

    assert_contains "$stderr_log" 'bash is required before installing Claude Code' \
      "install-claude-code.sh must explain the bash prerequisite"
  )
}

test_install_claude_code_skips_when_claude_exists() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_bin="$tmpdir/bin"
    curl_log="$tmpdir/curl.log"
    mkdir -p "$fake_bin"

    cat >"$fake_bin/claude" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/claude"

    cat >"$fake_bin/curl" <<EOF
#!/bin/sh
echo "\$*" >>"$curl_log"
exit 0
EOF
    make_executable "$fake_bin/curl"

    PATH="$fake_bin:/bin:/usr/bin" HOME="$tmpdir/home" /bin/sh "$install_script" >/dev/null

    assert_file_missing "$curl_log" "install-claude-code.sh should not invoke curl when claude already exists"
  )
}

test_install_claude_code_does_not_skip_cmux_bundled_claude() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    cmux_bin="$tmpdir/Applications/cmux.app/Contents/Resources/bin"
    fake_bin="$tmpdir/bin"
    home_dir="$tmpdir/home"
    curl_log="$tmpdir/curl.log"
    bash_log="$tmpdir/bash.log"
    stderr_log="$tmpdir/stderr.log"
    mkdir -p "$cmux_bin" "$fake_bin" "$home_dir"

    cat >"$cmux_bin/claude" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$cmux_bin/claude"

    cat >"$fake_bin/curl" <<EOF
#!/bin/sh
echo "\$*" >>"$curl_log"
cat >"\$4" <<'SCRIPT'
#!/bin/sh
exit 0
SCRIPT
EOF
    make_executable "$fake_bin/curl"

    cat >"$fake_bin/bash" <<EOF
#!/bin/sh
echo "\$*" >>"$bash_log"
exit 0
EOF
    make_executable "$fake_bin/bash"

    if PATH="$cmux_bin:$fake_bin:/bin:/usr/bin" HOME="$home_dir" /bin/sh "$install_script" 2>"$stderr_log"; then
      echo "install-claude-code.sh should fail when only the cmux-bundled claude is visible after install"
      exit 1
    fi

    assert_file_equals "$curl_log" '-fsSL https://claude.ai/install.sh -o '"$home_dir"'/.cache/claude-code/install.sh' \
      "install-claude-code.sh must not skip the cmux-bundled claude"
    assert_file_equals "$bash_log" '-s latest' \
      "install-claude-code.sh must run the native installer when only cmux provides claude"
    assert_contains "$stderr_log" 'only the cmux-bundled claude is visible on PATH' \
      "install-claude-code.sh must explain cmux PATH shadowing after install"
  )
}

test_install_claude_code_runs_native_latest_install() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_bin="$tmpdir/bin"
    home_dir="$tmpdir/home"
    curl_log="$tmpdir/curl.log"
    bash_log="$tmpdir/bash.log"
    mkdir -p "$fake_bin" "$home_dir"

    cat >"$fake_bin/curl" <<EOF
#!/bin/sh
echo "\$*" >>"$curl_log"
cat >"\$4" <<'SCRIPT'
#!/bin/sh
exit 0
SCRIPT
EOF
    make_executable "$fake_bin/curl"

    cat >"$fake_bin/bash" <<EOF
#!/bin/sh
echo "\$*" >>"$bash_log"
cat >"$fake_bin/claude" <<'SCRIPT'
#!/bin/sh
exit 0
SCRIPT
chmod +x "$fake_bin/claude"
EOF
    make_executable "$fake_bin/bash"

    PATH="$fake_bin:/bin:/usr/bin" HOME="$home_dir" /bin/sh "$install_script" >/dev/null

    assert_file_equals "$curl_log" '-fsSL https://claude.ai/install.sh -o '"$home_dir"'/.cache/claude-code/install.sh' \
      "install-claude-code.sh must download the native installer"
    assert_file_equals "$bash_log" '-s latest' \
      "install-claude-code.sh must request the latest native Claude Code version"
    assert_file_exists "$fake_bin/claude" \
      "install-claude-code.sh must leave a claude command available after installation"
  )
}

test_claude_docs() {
  assert_contains "$root_readme" 'scripts/common/install-claude-code.sh' \
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

test_apm_manages_skills() {
  assert_file_exists "$apm_yml" \
    "apm.yml must exist as the SoT for agent skills distribution"
  assert_contains "$apm_yml" 'HukuKaich0u/agent-kit/instructions' \
    "apm.yml must distribute the shared instruction files"
  assert_not_contains "$apm_yml" 'HukuKaich0u/agent-kit/instructions/core' \
    "apm.yml must not reference the removed core package path"
  assert_contains "$apm_yml" 'HukuKaich0u/agent-kit/skills/tooling/drawio' \
    "apm.yml must distribute the drawio skill previously vendored in-repo"
}

test_claude_module_wiring
test_darwin_homebrew_does_not_own_claude_code
test_install_claude_code_requires_curl
test_install_claude_code_requires_bash
test_install_claude_code_skips_when_claude_exists
test_install_claude_code_does_not_skip_cmux_bundled_claude
test_install_claude_code_runs_native_latest_install
test_claude_docs
test_apm_manages_skills

echo "claude code management test passed"
