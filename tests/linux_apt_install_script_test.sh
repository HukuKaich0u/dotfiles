#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
script="$repo_root/scripts/install-linux-packages.sh"
setup_script="$repo_root/scripts/setup-linux.sh"

assert_contains() {
  file="$1"
  pattern="$2"
  message="$3"

  if ! grep -Fq "$pattern" "$file"; then
    echo "$message"
    exit 1
  fi
}

if [ ! -x "$script" ]; then
  echo "apt install script is not executable: $script"
  exit 1
fi

if [ ! -x "$setup_script" ]; then
  echo "linux setup script is not executable: $setup_script"
  exit 1
fi

assert_contains "$script" 'core)' \
  "install-linux-packages.sh should accept the core profile"
assert_contains "$script" 'linux-extra)' \
  "install-linux-packages.sh should accept the linux-extra profile"
assert_contains "$script" 'ca-certificates' \
  "install-linux-packages.sh should include ca-certificates in core"
assert_contains "$script" 'curl' \
  "install-linux-packages.sh should include curl in core"
assert_contains "$script" 'apt-transport-https' \
  "install-linux-packages.sh should include apt-transport-https for the gcloud apt repo"
assert_contains "$script" 'gnupg' \
  "install-linux-packages.sh should include gnupg for the gcloud apt repo"
assert_contains "$script" 'zsh' \
  "install-linux-packages.sh should include zsh in core"
assert_contains "$script" 'unzip' \
  "install-linux-packages.sh should include unzip in core"
assert_contains "$script" 'build-essential' \
  "install-linux-packages.sh should include build-essential in core"
assert_contains "$script" 'locales' \
  "install-linux-packages.sh should include locales in core"
assert_contains "$script" 'packages.cloud.google.com' \
  "install-linux-packages.sh should configure the Google Cloud apt repository"
assert_contains "$script" 'google-cloud-cli' \
  "install-linux-packages.sh should install google-cloud-cli in core"
assert_contains "$script" 'docker-ce' \
  "install-linux-packages.sh should install docker-ce in linux-extra"
assert_contains "$script" 'docker-ce-cli' \
  "install-linux-packages.sh should install docker-ce-cli in linux-extra"
assert_contains "$script" 'containerd.io' \
  "install-linux-packages.sh should install containerd.io in linux-extra"
assert_contains "$script" 'docker-buildx-plugin' \
  "install-linux-packages.sh should install docker-buildx-plugin in linux-extra"
assert_contains "$script" 'docker-compose-plugin' \
  "install-linux-packages.sh should install docker-compose-plugin in linux-extra"
assert_contains "$script" 'download.docker.com' \
  "install-linux-packages.sh should configure the Docker apt repository"

assert_contains "$setup_script" 'install-linux-packages.sh core' \
  "setup-linux.sh should install the core apt profile"
assert_contains "$setup_script" "https://sh.rustup.rs" \
  "setup-linux.sh should bootstrap rustup from the official installer"
assert_contains "$setup_script" "sh -s -- -y" \
  "setup-linux.sh should run rustup-init non-interactively"
assert_contains "$setup_script" 'link-dotfiles.sh' \
  "setup-linux.sh should install dotfiles after package bootstrap"
assert_contains "$setup_script" 'with-docker' \
  "setup-linux.sh should offer an opt-in Docker setup flag"

echo "linux apt install script test passed"
