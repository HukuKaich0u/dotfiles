#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
script="$repo_root/scripts/bootstrap-ubuntu.sh"

if [ ! -f "$script" ]; then
  echo "bootstrap script not found: $script"
  exit 1
fi

if [ ! -x "$script" ]; then
  echo "bootstrap script is not executable: $script"
  exit 1
fi

set +e
output="$(env -i HOME="$HOME" PATH="/usr/bin:/bin:/usr/sbin:/sbin" "$script" 2>&1)"
status=$?
set -e

printf '%s\n' "$output"

if [ "$status" -eq 0 ]; then
  echo "bootstrap script should fail outside Ubuntu"
  exit 1
fi

if ! printf '%s' "$output" | grep -qi "ubuntu"; then
  echo "bootstrap script did not explain Ubuntu-only requirement"
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

fake_bin="$tmp_dir/bin"
fake_repo="$tmp_dir/repo"
log_file="$tmp_dir/log.txt"
os_release="$tmp_dir/os-release"

mkdir -p "$fake_bin" "$fake_repo"

cat >"$os_release" <<'EOF'
ID=ubuntu
EOF

cat >"$fake_repo/install.sh" <<'EOF'
#!/bin/sh
echo "install.sh" >>"$LOG_FILE"
EOF
chmod +x "$fake_repo/install.sh"

cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
"$@"
EOF
chmod +x "$fake_bin/sudo"

cat >"$fake_bin/apt" <<'EOF'
#!/bin/sh
printf 'apt %s\n' "$*" >>"$LOG_FILE"
EOF
chmod +x "$fake_bin/apt"

cat >"$fake_bin/npm" <<'EOF'
#!/bin/sh
printf 'npm %s\n' "$*" >>"$LOG_FILE"
cat >"$(dirname "$0")/codex" <<'INNER'
#!/bin/sh
exit 0
INNER
chmod +x "$(dirname "$0")/codex"
EOF
chmod +x "$fake_bin/npm"

cat >"$fake_bin/chsh" <<'EOF'
#!/bin/sh
printf 'chsh %s\n' "$*" >>"$LOG_FILE"
exit 0
EOF
chmod +x "$fake_bin/chsh"

cat >"$fake_bin/zsh" <<'EOF'
#!/bin/sh
exit 0
EOF
chmod +x "$fake_bin/zsh"

rm -f "$log_file"
set +e
output="$(
  env -i \
  HOME="$tmp_dir/home" \
  PATH="$fake_bin:/usr/bin:/bin" \
  LOG_FILE="$log_file" \
  BOOTSTRAP_OS_RELEASE="$os_release" \
  BOOTSTRAP_DOTFILES_DIR="$fake_repo" \
  SHELL="/bin/sh" \
  "$script" 2>&1
)"
status=$?
set -e

printf '%s\n' "$output"

if [ "$status" -ne 0 ]; then
  echo "bootstrap script should run with mocked Ubuntu commands"
  exit 1
fi

if ! grep -q 'apt update' "$log_file"; then
  echo "bootstrap script did not run apt update"
  exit 1
fi

if ! grep -q 'apt install -y' "$log_file"; then
  echo "bootstrap script did not run apt install"
  exit 1
fi

if ! grep -q 'npm install -g @openai/codex' "$log_file"; then
  echo "bootstrap script did not install codex"
  exit 1
fi

if ! grep -q 'install.sh' "$log_file"; then
  echo "bootstrap script did not run install.sh"
  exit 1
fi
