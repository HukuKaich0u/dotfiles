#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
packages_script="$repo_root/scripts/install-linux-packages.sh"
setup_script="$repo_root/scripts/setup-linux.sh"
rustup_script="$repo_root/scripts/install-rustup.sh"

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

test_install_rustup_behaviors() {
  run_install_rustup_test "PATH rustup" yes no 0
  run_install_rustup_test "HOME rustup" no yes 0
  run_install_rustup_test "missing rustup" no no 1
  test_install_rustup_download_failure
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
assert_contains "$setup_script" 'link-dotfiles.sh' \
  "setup-linux.sh should install dotfiles after package bootstrap"
assert_contains "$setup_script" 'with-docker' \
  "setup-linux.sh should offer an opt-in Docker setup flag"

test_install_rustup_behaviors
test_setup_linux_order

echo "linux apt install script test passed"
