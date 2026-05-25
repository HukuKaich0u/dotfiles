#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
packages_script="$repo_root/scripts/install-linux-packages.sh"
setup_script="$repo_root/scripts/setup-linux.sh"
rustup_script="$repo_root/scripts/install-rustup.sh"
ghostty_script="$repo_root/scripts/install-ghostty-linux.sh"
root_readme="$repo_root/README.md"
scripts_readme="$repo_root/scripts/README.md"

assert_contains() {
  file="$1"
  pattern="$2"
  message="$3"

  if ! grep -Fq "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

create_temp_dir() {
  mktemp -d "${TMPDIR:-/tmp}/linux-script-test.XXXXXX"
}

make_executable() {
  chmod +x "$1"
}

assert_file_mode() {
  path="$1"
  expected="$2"
  message="$3"

  if [ ! -e "$path" ]; then
    echo "$message"
    exit 1
  fi

  actual="$(stat -f '%Lp' "$path")"
  if [ "$actual" != "$expected" ]; then
    echo "$message"
    printf 'expected mode:\n%s\nactual mode:\n%s\n' "$expected" "$actual"
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

assert_file_exists() {
  path="$1"
  message="$2"

  if [ ! -e "$path" ]; then
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

assert_file_contains() {
  path="$1"
  needle="$2"
  message="$3"

  if [ ! -f "$path" ]; then
    echo "$message"
    exit 1
  fi

  if ! grep -Fq "$needle" "$path"; then
    echo "$message"
    exit 1
  fi
}

run_install_rustup_test() {
  scenario="$1"
  rustup_on_path="$2"
  rustup_in_home="$3"
  expected_installer_calls="$4"

  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    home_dir="$tmpdir/home"
    fake_bin="$tmpdir/bin"
    curl_log="$tmpdir/curl.log"
    installer_log="$tmpdir/installer.log"
    touch "$curl_log"

    mkdir -p "$home_dir/.cargo/bin" "$fake_bin"

    if [ "$rustup_on_path" = "yes" ]; then
      cat >"$fake_bin/rustup" <<'EOF'
#!/bin/sh
exit 0
EOF
      make_executable "$fake_bin/rustup"
    fi

    if [ "$rustup_in_home" = "yes" ]; then
      cat >"$home_dir/.cargo/bin/rustup" <<'EOF'
#!/bin/sh
exit 0
EOF
      make_executable "$home_dir/.cargo/bin/rustup"
    fi

    cat >"$fake_bin/curl" <<EOF
#!/bin/sh
echo curl >>"$curl_log"

output_file=""
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    -o)
      output_file="\$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

cat >"\$output_file" <<'SCRIPT'
#!/bin/sh
echo "\$*" >>"$installer_log"
SCRIPT
EOF
    make_executable "$fake_bin/curl"

    HOME="$home_dir" PATH="$fake_bin:/bin:/usr/bin" /bin/sh "$rustup_script"

    case "$expected_installer_calls" in
      0)
        assert_file_equals "$curl_log" "" "$scenario: curl should not run when rustup already exists"
        assert_file_missing "$installer_log" "$scenario: installer should not run when rustup already exists"
        ;;
      1)
        assert_file_equals "$curl_log" "curl" "$scenario: curl should run exactly once when rustup is absent"
        assert_file_equals "$installer_log" "-y" "$scenario: installer should receive -y when rustup is absent"
        ;;
      *)
        echo "unsupported expectation: $expected_installer_calls"
        exit 1
        ;;
    esac
  )
}

test_install_rustup_download_failure() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    home_dir="$tmpdir/home"
    fake_bin="$tmpdir/bin"
    sh_log="$tmpdir/sh.log"
    mkdir -p "$home_dir" "$fake_bin"

    cat >"$fake_bin/curl" <<'EOF'
#!/bin/sh
exit 7
EOF
    make_executable "$fake_bin/curl"

    cat >"$fake_bin/sh" <<EOF
#!/bin/sh
echo invoked >>"$sh_log"
exit 0
EOF
    make_executable "$fake_bin/sh"

    if HOME="$home_dir" PATH="$fake_bin:/bin:/usr/bin" /bin/sh "$rustup_script"; then
      echo "install-rustup.sh should fail when the rustup installer download fails"
      exit 1
    fi

    assert_file_missing "$sh_log" "install-rustup.sh should not invoke the installer shell when curl fails"
  )
}

test_install_rustup_requires_curl() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    home_dir="$tmpdir/home"
    fake_bin="$tmpdir/bin"
    stderr_log="$tmpdir/stderr.log"
    mkdir -p "$home_dir" "$fake_bin"

    if HOME="$home_dir" PATH="$fake_bin" /bin/sh "$rustup_script" 2>"$stderr_log"; then
      echo "install-rustup.sh should fail when curl is unavailable"
      exit 1
    fi

    assert_file_contains "$stderr_log" 'curl is required before installing rustup' \
      "install-rustup.sh should explain the missing curl prerequisite"
  )
}

test_install_rustup_behaviors() {
  run_install_rustup_test "PATH rustup" yes no 0
  run_install_rustup_test "HOME rustup" no yes 0
  run_install_rustup_test "missing rustup" no no 1
  test_install_rustup_download_failure
  test_install_rustup_requires_curl
}

test_setup_linux_order() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    scripts_dir="$tmpdir/scripts"
    log_file="$tmpdir/calls.log"
    mkdir -p "$scripts_dir"

    cp "$setup_script" "$scripts_dir/setup-linux.sh"
    make_executable "$scripts_dir/setup-linux.sh"

    cat >"$scripts_dir/install-linux-packages.sh" <<EOF
#!/bin/sh
echo "install-linux-packages:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/install-linux-packages.sh"

    cat >"$scripts_dir/install-rustup.sh" <<EOF
#!/bin/sh
echo "install-rustup:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/install-rustup.sh"

    cat >"$scripts_dir/link-dotfiles.sh" <<EOF
#!/bin/sh
echo "link-dotfiles:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/link-dotfiles.sh"

    HOME="$tmpdir/home" PATH="/bin:/usr/bin" /bin/sh "$scripts_dir/setup-linux.sh"

    assert_file_equals "$log_file" \
"install-linux-packages:core
install-rustup:
link-dotfiles:" \
      "setup-linux.sh should call package install, rustup install, then link-dotfiles in order"
  )
}

test_setup_linux_with_ghostty_order() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    scripts_dir="$tmpdir/scripts"
    log_file="$tmpdir/calls.log"
    mkdir -p "$scripts_dir"

    cp "$setup_script" "$scripts_dir/setup-linux.sh"
    make_executable "$scripts_dir/setup-linux.sh"

    cat >"$scripts_dir/install-linux-packages.sh" <<EOF
#!/bin/sh
echo "install-linux-packages:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/install-linux-packages.sh"

    cat >"$scripts_dir/install-ghostty-linux.sh" <<EOF
#!/bin/sh
echo "install-ghostty-linux:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/install-ghostty-linux.sh"

    cat >"$scripts_dir/install-rustup.sh" <<EOF
#!/bin/sh
echo "install-rustup:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/install-rustup.sh"

    cat >"$scripts_dir/link-dotfiles.sh" <<EOF
#!/bin/sh
echo "link-dotfiles:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/link-dotfiles.sh"

    HOME="$tmpdir/home" PATH="/bin:/usr/bin" /bin/sh "$scripts_dir/setup-linux.sh" --with-ghostty

    assert_file_equals "$log_file" \
"install-linux-packages:core
install-ghostty-linux:
install-rustup:
link-dotfiles:" \
      "setup-linux.sh should call Ghostty install between core packages and rustup when --with-ghostty is set"
  )
}

test_setup_linux_with_docker_and_ghostty_order() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    scripts_dir="$tmpdir/scripts"
    log_file="$tmpdir/calls.log"
    mkdir -p "$scripts_dir"

    cp "$setup_script" "$scripts_dir/setup-linux.sh"
    make_executable "$scripts_dir/setup-linux.sh"

    cat >"$scripts_dir/install-linux-packages.sh" <<EOF
#!/bin/sh
echo "install-linux-packages:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/install-linux-packages.sh"

    cat >"$scripts_dir/install-ghostty-linux.sh" <<EOF
#!/bin/sh
echo "install-ghostty-linux:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/install-ghostty-linux.sh"

    cat >"$scripts_dir/install-rustup.sh" <<EOF
#!/bin/sh
echo "install-rustup:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/install-rustup.sh"

    cat >"$scripts_dir/link-dotfiles.sh" <<EOF
#!/bin/sh
echo "link-dotfiles:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/link-dotfiles.sh"

    HOME="$tmpdir/home" PATH="/bin:/usr/bin" /bin/sh "$scripts_dir/setup-linux.sh" --with-docker --with-ghostty

    assert_file_equals "$log_file" \
"install-linux-packages:core
install-linux-packages:linux-extra
install-ghostty-linux:
install-rustup:
link-dotfiles:" \
      "setup-linux.sh should install docker before Ghostty and finish with rustup and dotfiles when both flags are set"
  )
}

prepare_patched_linux_packages_script() {
  target_script="$1"
  fake_root="$2"
  os_release_path="$fake_root/os-release"

  mkdir -p "$fake_root/usr/share/keyrings" \
    "$fake_root/etc/apt/sources.list.d" \
    "$fake_root/etc/apt/keyrings"

  cat >"$os_release_path" <<'EOF'
ID=ubuntu
VERSION_CODENAME=noble
EOF

  sed \
    -e "s|/etc/os-release|$os_release_path|g" \
    -e "s|/etc/apt/sources.list.d/google-cloud-sdk.list|$fake_root/etc/apt/sources.list.d/google-cloud-sdk.list|g" \
    -e "s|/etc/apt/sources.list.d/docker.list|$fake_root/etc/apt/sources.list.d/docker.list|g" \
    -e "s|/usr/share/keyrings|$fake_root/usr/share/keyrings|g" \
    -e "s|/etc/apt/keyrings|$fake_root/etc/apt/keyrings|g" \
    "$packages_script" >"$target_script"
  make_executable "$target_script"
}

prepare_patched_ghostty_script() {
  target_script="$1"
  fake_root="$2"
  os_release_path="$fake_root/os-release"

  mkdir -p "$fake_root"

  cat >"$os_release_path" <<'EOF'
ID=ubuntu
VERSION_CODENAME=noble
EOF

  sed \
    -e "s|/etc/os-release|$os_release_path|g" \
    "$ghostty_script" >"$target_script"
  make_executable "$target_script"
}

test_linux_package_repo_idempotency() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_root="$tmpdir/root"
    fake_bin="$tmpdir/bin"
    log_dir="$tmpdir/logs"
    script_under_test="$tmpdir/install-linux-packages.sh"
    mkdir -p "$fake_bin" "$log_dir"

    prepare_patched_linux_packages_script "$script_under_test" "$fake_root"

    cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
"$@"
EOF
    make_executable "$fake_bin/sudo"

    cat >"$fake_bin/apt-get" <<EOF
#!/bin/sh
echo "\$*" >>"$log_dir/apt-get.log"
exit 0
EOF
    make_executable "$fake_bin/apt-get"

    cat >"$fake_bin/curl" <<EOF
#!/bin/sh
echo "\$*" >>"$log_dir/curl.log"
output_file=""
url=""
while [ "\$#" -gt 0 ]; do
  case "\$1" in
    -o)
      output_file="\$2"
      shift 2
      ;;
    *)
      url="\$1"
      shift
      ;;
  esac
done

case "\$url" in
  *packages.cloud.google.com*)
    printf 'google-key\n' >"\$output_file"
    ;;
  *download.docker.com*)
    printf 'docker-key\n' >"\$output_file"
    ;;
  *)
    exit 1
    ;;
esac
EOF
    make_executable "$fake_bin/curl"

    cat >"$fake_bin/gpg" <<'EOF'
#!/bin/sh
if [ "$1" = "--dearmor" ] && [ "$2" = "--output" ]; then
  cat "$4" >"$3"
  exit 0
fi
exit 1
EOF
    make_executable "$fake_bin/gpg"

    cat >"$fake_bin/chown" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/chown"

    cat >"$fake_bin/dpkg" <<'EOF'
#!/bin/sh
if [ "$1" = "--print-architecture" ]; then
  echo amd64
  exit 0
fi
exit 1
EOF
    make_executable "$fake_bin/dpkg"

    PATH="$fake_bin:/bin:/usr/bin" /bin/sh "$script_under_test" core
    PATH="$fake_bin:/bin:/usr/bin" /bin/sh "$script_under_test" core

    assert_file_equals "$fake_root/etc/apt/sources.list.d/google-cloud-sdk.list" \
"deb [signed-by=$fake_root/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
      "core profile should write the Google Cloud apt source once"
    assert_file_equals "$fake_root/usr/share/keyrings/cloud.google.gpg" "google-key" \
      "core profile should write the Google Cloud keyring"
    assert_file_equals "$log_dir/apt-get.log" \
"update
install -y apt-transport-https ca-certificates curl gnupg
update
update
install -y zsh unzip build-essential locales google-cloud-cli
update
install -y apt-transport-https ca-certificates curl gnupg
update
install -y zsh unzip build-essential locales google-cloud-cli" \
      "re-running core should skip the repo-refresh apt update when repo files are unchanged"

    : >"$log_dir/apt-get.log"

    PATH="$fake_bin:/bin:/usr/bin" /bin/sh "$script_under_test" linux-extra
    PATH="$fake_bin:/bin:/usr/bin" /bin/sh "$script_under_test" linux-extra

    assert_file_equals "$fake_root/etc/apt/sources.list.d/docker.list" \
"deb [arch=amd64 signed-by=$fake_root/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" \
      "linux-extra should write the Docker apt source once"
    assert_file_equals "$fake_root/etc/apt/keyrings/docker.gpg" "docker-key" \
      "linux-extra should write the Docker keyring"
    assert_file_equals "$log_dir/apt-get.log" \
"update
install -y ca-certificates curl gnupg
update
install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
update
install -y ca-certificates curl gnupg
install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin" \
      "re-running linux-extra should skip the repo-refresh apt update when repo files are unchanged"
  )
}

test_linux_package_keyring_mode_repair() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_root="$tmpdir/root"
    fake_bin="$tmpdir/bin"
    log_dir="$tmpdir/logs"
    script_under_test="$tmpdir/install-linux-packages.sh"
    mkdir -p "$fake_bin" "$log_dir"

    prepare_patched_linux_packages_script "$script_under_test" "$fake_root"

    cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
"$@"
EOF
    make_executable "$fake_bin/sudo"

    cat >"$fake_bin/apt-get" <<EOF
#!/bin/sh
echo "\$*" >>"$log_dir/apt-get.log"
exit 0
EOF
    make_executable "$fake_bin/apt-get"

    cat >"$fake_bin/curl" <<'EOF'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o)
      output_file="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
printf 'google-key\n' >"$output_file"
EOF
    make_executable "$fake_bin/curl"

    cat >"$fake_bin/gpg" <<'EOF'
#!/bin/sh
if [ "$1" = "--dearmor" ] && [ "$2" = "--output" ]; then
  cat "$4" >"$3"
  exit 0
fi
exit 1
EOF
    make_executable "$fake_bin/gpg"

    cat >"$fake_bin/chown" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/chown"

    PATH="$fake_bin:/bin:/usr/bin" /bin/sh "$script_under_test" core

    chmod 0600 "$fake_root/usr/share/keyrings/cloud.google.gpg"
    assert_file_mode "$fake_root/usr/share/keyrings/cloud.google.gpg" "600" \
      "test setup should drift the Google Cloud keyring mode"

    PATH="$fake_bin:/bin:/usr/bin" /bin/sh "$script_under_test" core

    assert_file_mode "$fake_root/usr/share/keyrings/cloud.google.gpg" "644" \
      "re-running core should repair Google Cloud keyring readability drift"
  )
}

test_linux_package_keyring_download_failure() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_root="$tmpdir/root"
    fake_bin="$tmpdir/bin"
    script_under_test="$tmpdir/install-linux-packages.sh"
    mkdir -p "$fake_bin"

    prepare_patched_linux_packages_script "$script_under_test" "$fake_root"

    cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
"$@"
EOF
    make_executable "$fake_bin/sudo"

    cat >"$fake_bin/apt-get" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/apt-get"

    cat >"$fake_bin/curl" <<'EOF'
#!/bin/sh
exit 7
EOF
    make_executable "$fake_bin/curl"

    cat >"$fake_bin/gpg" <<'EOF'
#!/bin/sh
if [ "$1" = "--dearmor" ] && [ "$2" = "--output" ]; then
  cat "$4" >"$3"
  exit 0
fi
exit 1
EOF
    make_executable "$fake_bin/gpg"

    cat >"$fake_bin/chown" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/chown"

    if PATH="$fake_bin:/bin:/usr/bin" /bin/sh "$script_under_test" core; then
      echo "install-linux-packages.sh should fail when the Google Cloud keyring download fails"
      exit 1
    fi
  )
}

test_install_linux_packages_requires_base_commands() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_root="$tmpdir/root"
    fake_bin="$tmpdir/bin"
    script_under_test="$tmpdir/install-linux-packages.sh"
    stderr_log="$tmpdir/stderr.log"
    mkdir -p "$fake_bin"

    prepare_patched_linux_packages_script "$script_under_test" "$fake_root"

    if PATH="$fake_bin" /bin/sh "$script_under_test" core 2>"$stderr_log"; then
      echo "install-linux-packages.sh should fail when sudo is unavailable"
      exit 1
    fi

    assert_file_contains "$stderr_log" 'sudo is required before installing Linux packages' \
      "install-linux-packages.sh should explain the missing sudo prerequisite"
  )
}

test_install_linux_packages_requires_apt_get() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_root="$tmpdir/root"
    fake_bin="$tmpdir/bin"
    script_under_test="$tmpdir/install-linux-packages.sh"
    stderr_log="$tmpdir/stderr.log"
    mkdir -p "$fake_bin"

    prepare_patched_linux_packages_script "$script_under_test" "$fake_root"

    cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
"$@"
EOF
    make_executable "$fake_bin/sudo"

    if PATH="$fake_bin" /bin/sh "$script_under_test" core 2>"$stderr_log"; then
      echo "install-linux-packages.sh should fail when apt-get is unavailable"
      exit 1
    fi

    assert_file_contains "$stderr_log" 'apt-get is required before installing Linux packages' \
      "install-linux-packages.sh should explain the missing apt-get prerequisite"
  )
}

test_install_linux_packages_requires_curl() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_root="$tmpdir/root"
    fake_bin="$tmpdir/bin"
    script_under_test="$tmpdir/install-linux-packages.sh"
    stderr_log="$tmpdir/stderr.log"
    mkdir -p "$fake_bin"

    prepare_patched_linux_packages_script "$script_under_test" "$fake_root"

    cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
"$@"
EOF
    make_executable "$fake_bin/sudo"

    cat >"$fake_bin/apt-get" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/apt-get"

    if PATH="$fake_bin" /bin/sh "$script_under_test" core 2>"$stderr_log"; then
      echo "install-linux-packages.sh should fail when curl is unavailable"
      exit 1
    fi

    assert_file_contains "$stderr_log" 'curl is required before configuring apt repositories' \
      "install-linux-packages.sh should explain the missing curl prerequisite"
  )
}

test_install_linux_packages_requires_gpg() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_root="$tmpdir/root"
    fake_bin="$tmpdir/bin"
    script_under_test="$tmpdir/install-linux-packages.sh"
    stderr_log="$tmpdir/stderr.log"
    mkdir -p "$fake_bin"

    prepare_patched_linux_packages_script "$script_under_test" "$fake_root"

    cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
"$@"
EOF
    make_executable "$fake_bin/sudo"

    cat >"$fake_bin/apt-get" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/apt-get"

    cat >"$fake_bin/curl" <<'EOF'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o)
      output_file="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
printf 'google-key\n' >"$output_file"
EOF
    make_executable "$fake_bin/curl"

    if PATH="$fake_bin" /bin/sh "$script_under_test" core 2>"$stderr_log"; then
      echo "install-linux-packages.sh should fail when gpg is unavailable"
      exit 1
    fi

    assert_file_contains "$stderr_log" 'gpg is required before configuring apt repositories' \
      "install-linux-packages.sh should explain the missing gpg prerequisite"
  )
}

test_install_linux_packages_requires_dpkg_for_linux_extra() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_root="$tmpdir/root"
    fake_bin="$tmpdir/bin"
    script_under_test="$tmpdir/install-linux-packages.sh"
    stderr_log="$tmpdir/stderr.log"
    mkdir -p "$fake_bin"

    prepare_patched_linux_packages_script "$script_under_test" "$fake_root"

    cat >"$fake_bin/sudo" <<'EOF'
#!/bin/sh
"$@"
EOF
    make_executable "$fake_bin/sudo"

    cat >"$fake_bin/apt-get" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/apt-get"

    cat >"$fake_bin/curl" <<'EOF'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  case "$1" in
    -o)
      output_file="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
printf 'docker-key\n' >"$output_file"
EOF
    make_executable "$fake_bin/curl"

    cat >"$fake_bin/gpg" <<'EOF'
#!/bin/sh
if [ "$1" = "--dearmor" ] && [ "$2" = "--output" ]; then
  cat "$4" >"$3"
  exit 0
fi
exit 1
EOF
    make_executable "$fake_bin/gpg"

    cat >"$fake_bin/chown" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/chown"

    if PATH="$fake_bin" /bin/sh "$script_under_test" linux-extra 2>"$stderr_log"; then
      echo "install-linux-packages.sh should fail when dpkg is unavailable for linux-extra"
      exit 1
    fi

    assert_file_contains "$stderr_log" 'dpkg is required before configuring the Docker apt repository' \
      "install-linux-packages.sh should explain the missing dpkg prerequisite"
  )
}

test_install_ghostty_linux_requires_curl() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    stderr_log="$tmpdir/stderr.log"
    fake_bin="$tmpdir/bin"
    mkdir -p "$fake_bin"

    if PATH="$fake_bin" /bin/sh "$ghostty_script" 2>"$stderr_log"; then
      echo "install-ghostty-linux.sh should fail when curl is unavailable"
      exit 1
    fi

    assert_file_contains "$stderr_log" 'curl is required before installing Ghostty' \
      "install-ghostty-linux.sh should explain the missing curl prerequisite"
  )
}

test_install_ghostty_linux_skips_when_present() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_bin="$tmpdir/bin"
    curl_log="$tmpdir/curl.log"
    mkdir -p "$fake_bin"
    : >"$curl_log"

    cat >"$fake_bin/ghostty" <<'EOF'
#!/bin/sh
exit 0
EOF
    make_executable "$fake_bin/ghostty"

    cat >"$fake_bin/curl" <<EOF
#!/bin/sh
echo curl >>"$curl_log"
exit 0
EOF
    make_executable "$fake_bin/curl"

    PATH="$fake_bin:/bin:/usr/bin" /bin/sh "$ghostty_script"

    assert_file_equals "$curl_log" "" \
      "install-ghostty-linux.sh should not invoke curl when ghostty is already installed"
  )
}

test_install_ghostty_linux_runs_official_installer() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    fake_root="$tmpdir/root"
    fake_bin="$tmpdir/bin"
    script_under_test="$tmpdir/install-ghostty-linux.sh"
    curl_log="$tmpdir/curl.log"
    installer_log="$tmpdir/installer.log"
    mkdir -p "$fake_bin"

    prepare_patched_ghostty_script "$script_under_test" "$fake_root"

    cat >"$fake_bin/curl" <<EOF
#!/bin/sh
echo "\$*" >>"$curl_log"
cat <<'SCRIPT'
echo ran >>"$installer_log"
SCRIPT
EOF
    make_executable "$fake_bin/curl"

    PATH="$fake_bin:/bin:/usr/bin" /bin/sh "$script_under_test"

    assert_file_contains "$curl_log" 'https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh' \
      "install-ghostty-linux.sh should fetch the documented Ghostty Ubuntu installer"
    assert_file_equals "$installer_log" "ran" \
      "install-ghostty-linux.sh should execute the downloaded installer body"
  )
}

if [ ! -x "$packages_script" ]; then
  echo "apt install script is not executable: $packages_script"
  exit 1
fi

if [ ! -x "$setup_script" ]; then
  echo "linux setup script is not executable: $setup_script"
  exit 1
fi

if [ ! -x "$rustup_script" ]; then
  echo "rustup install script is not executable: $rustup_script"
  exit 1
fi

if [ ! -x "$ghostty_script" ]; then
  echo "ghostty install script is not executable: $ghostty_script"
  exit 1
fi

assert_contains "$packages_script" 'core)' \
  "install-linux-packages.sh should accept the core profile"
assert_contains "$packages_script" 'linux-extra)' \
  "install-linux-packages.sh should accept the linux-extra profile"
assert_contains "$packages_script" 'ca-certificates' \
  "install-linux-packages.sh should include ca-certificates in core"
assert_contains "$packages_script" 'curl' \
  "install-linux-packages.sh should include curl in core"
assert_contains "$packages_script" 'apt-transport-https' \
  "install-linux-packages.sh should include apt-transport-https for the gcloud apt repo"
assert_contains "$packages_script" 'gnupg' \
  "install-linux-packages.sh should include gnupg for the gcloud apt repo"
assert_contains "$packages_script" 'zsh' \
  "install-linux-packages.sh should include zsh in core"
assert_contains "$packages_script" 'unzip' \
  "install-linux-packages.sh should include unzip in core"
assert_contains "$packages_script" 'build-essential' \
  "install-linux-packages.sh should include build-essential in core"
assert_contains "$packages_script" 'locales' \
  "install-linux-packages.sh should include locales in core"
assert_contains "$packages_script" 'packages.cloud.google.com' \
  "install-linux-packages.sh should configure the Google Cloud apt repository"
assert_contains "$packages_script" 'google-cloud-cli' \
  "install-linux-packages.sh should install google-cloud-cli in core"
assert_contains "$packages_script" 'docker-ce' \
  "install-linux-packages.sh should install docker-ce in linux-extra"
assert_contains "$packages_script" 'docker-ce-cli' \
  "install-linux-packages.sh should install docker-ce-cli in linux-extra"
assert_contains "$packages_script" 'containerd.io' \
  "install-linux-packages.sh should install containerd.io in linux-extra"
assert_contains "$packages_script" 'docker-buildx-plugin' \
  "install-linux-packages.sh should install docker-buildx-plugin in linux-extra"
assert_contains "$packages_script" 'docker-compose-plugin' \
  "install-linux-packages.sh should install docker-compose-plugin in linux-extra"
assert_contains "$packages_script" 'download.docker.com' \
  "install-linux-packages.sh should configure the Docker apt repository"

assert_contains "$setup_script" 'install-linux-packages.sh core' \
  "setup-linux.sh should install the core apt profile"
assert_contains "$setup_script" 'install-rustup.sh' \
  "setup-linux.sh should delegate rustup installation to the shared script"
assert_contains "$setup_script" 'install-ghostty-linux.sh' \
  "setup-linux.sh should delegate Ghostty installation to a dedicated script"
assert_contains "$setup_script" 'link-dotfiles.sh' \
  "setup-linux.sh should install dotfiles after package bootstrap"
assert_contains "$setup_script" 'with-docker' \
  "setup-linux.sh should offer an opt-in Docker setup flag"
assert_contains "$setup_script" 'with-ghostty' \
  "setup-linux.sh should offer an opt-in Ghostty setup flag"
assert_contains "$root_readme" './scripts/setup-linux.sh --with-ghostty' \
  "README.md must document the opt-in Ghostty Linux bootstrap command"
assert_contains "$scripts_readme" './scripts/setup-linux.sh --with-ghostty' \
  "scripts/README.md must document the Ghostty desktop bootstrap command"
assert_contains "$scripts_readme" 'install-ghostty-linux.sh' \
  "scripts/README.md must describe install-ghostty-linux.sh"

test_install_rustup_behaviors
test_setup_linux_order
test_setup_linux_with_ghostty_order
test_setup_linux_with_docker_and_ghostty_order
test_linux_package_repo_idempotency
test_linux_package_keyring_mode_repair
test_linux_package_keyring_download_failure
test_install_linux_packages_requires_base_commands
test_install_linux_packages_requires_apt_get
test_install_linux_packages_requires_curl
test_install_linux_packages_requires_gpg
test_install_linux_packages_requires_dpkg_for_linux_extra
test_install_ghostty_linux_requires_curl
test_install_ghostty_linux_skips_when_present
test_install_ghostty_linux_runs_official_installer

echo "linux apt install script test passed"
