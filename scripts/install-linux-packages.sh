#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/install-linux-packages.sh <profile>

Profiles:
  core         Install base Linux packages required before Home Manager setup
  linux-extra  Install Docker CE packages from Docker's official apt repository
EOF
}

require_supported_distro() {
  if [ ! -r /etc/os-release ]; then
    echo "Unsupported Linux distribution: /etc/os-release not found" >&2
    exit 1
  fi

  . /etc/os-release

  case "${ID:-}" in
    ubuntu|debian)
      :
      ;;
    *)
      echo "Unsupported Linux distribution: ${ID:-unknown}. This script supports Debian/Ubuntu only." >&2
      exit 1
      ;;
  esac
}

apt_install() {
  sudo apt-get update
  sudo apt-get install -y "$@"
}

install_google_cloud_repo() {
  apt_install apt-transport-https ca-certificates curl gnupg
  sudo install -d -m 0755 /usr/share/keyrings
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list >/dev/null
  sudo apt-get update
}

install_core() {
  install_google_cloud_repo
  apt_install \
    zsh \
    unzip \
    build-essential \
    locales \
    google-cloud-cli
}

install_linux_extra() {
  require_supported_distro
  . /etc/os-release

  apt_install ca-certificates curl gnupg
  sudo install -m 0755 -d /etc/apt/keyrings
  curl -fsSL "https://download.docker.com/linux/${ID}/gpg" | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
}

main() {
  if [ "$#" -ne 1 ]; then
    usage >&2
    exit 1
  fi

  case "$1" in
    -h|--help)
      usage
      ;;
    core)
      require_supported_distro
      install_core
      ;;
    linux-extra)
      require_supported_distro
      install_linux_extra
      ;;
    *)
      echo "Unknown profile: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
}

main "$@"
