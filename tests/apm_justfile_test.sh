#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
justfile="$repo_root/justfile"

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

if ! command -v just >/dev/null 2>&1; then
  echo "just is required for apm_justfile_test.sh"
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM

home_dir="$tmp_dir/home"
fake_bin="$tmp_dir/bin"
log_file="$tmp_dir/apm.log"
mkdir -p "$home_dir" "$fake_bin"

cat >"$fake_bin/apm" <<'EOF'
#!/bin/sh
printf '%s|%s\n' "$APM_COPILOT_COWORK_SKILLS_DIR" "$*" >>"$APM_TEST_LOG"
EOF
chmod +x "$fake_bin/apm"

HOME="$home_dir" \
  PATH="$fake_bin:$PATH" \
  APM_TEST_LOG="$log_file" \
  just --justfile "$justfile" apm-install >/dev/null

expected_install="$home_dir/.local/share/copilot-cowork/skills|install -g
$home_dir/.local/share/copilot-cowork/skills|compile -g"
assert_file_equals "$log_file" "$expected_install" \
  "apm-install must set the Cowork path, install globally, then compile"

: >"$log_file"

HOME="$home_dir" \
  PATH="$fake_bin:$PATH" \
  APM_TEST_LOG="$log_file" \
  just --justfile "$justfile" apm-update >/dev/null

expected_update="$home_dir/.local/share/copilot-cowork/skills|update -g --yes
$home_dir/.local/share/copilot-cowork/skills|compile -g"
assert_file_equals "$log_file" "$expected_update" \
  "apm-update must set the Cowork path, update globally, then compile"

echo "apm justfile test passed"
