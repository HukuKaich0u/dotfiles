#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
script="$repo_root/scripts/install-apt-packages.sh"

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

assert_contains "$script" 'core)' \
  "install-apt-packages.sh should accept the core profile"
assert_contains "$script" 'linux-extra)' \
  "install-apt-packages.sh should accept the linux-extra profile"
assert_contains "$script" 'ca-certificates' \
  "install-apt-packages.sh should include ca-certificates in core"
assert_contains "$script" 'curl' \
  "install-apt-packages.sh should include curl in core"
assert_contains "$script" 'zsh' \
  "install-apt-packages.sh should include zsh in core"
assert_contains "$script" 'unzip' \
  "install-apt-packages.sh should include unzip in core"
assert_contains "$script" 'build-essential' \
  "install-apt-packages.sh should include build-essential in core"
assert_contains "$script" 'locales' \
  "install-apt-packages.sh should include locales in core"
assert_contains "$script" 'docker-ce' \
  "install-apt-packages.sh should install docker-ce in linux-extra"
assert_contains "$script" 'docker-ce-cli' \
  "install-apt-packages.sh should install docker-ce-cli in linux-extra"
assert_contains "$script" 'containerd.io' \
  "install-apt-packages.sh should install containerd.io in linux-extra"
assert_contains "$script" 'docker-buildx-plugin' \
  "install-apt-packages.sh should install docker-buildx-plugin in linux-extra"
assert_contains "$script" 'docker-compose-plugin' \
  "install-apt-packages.sh should install docker-compose-plugin in linux-extra"
assert_contains "$script" 'download.docker.com' \
  "install-apt-packages.sh should configure the Docker apt repository"

echo "linux apt install script test passed"
