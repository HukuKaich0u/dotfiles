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

install_file_if_changed() {
  src="$1"
  dest="$2"
  mode="$3"
  dest_dir="$(dirname "$dest")"

  if sudo test -f "$dest" && sudo cmp -s "$src" "$dest"; then
    return 1
  fi

  sudo install -d -m 0755 "$dest_dir"
  sudo install -m "$mode" "$src" "$dest"
}

sync_keyring() {
  url="$1"
  dest="$2"
  tmp="$(mktemp)"

  cleanup() {
    rm -f "$tmp"
  }

  trap cleanup EXIT HUP INT TERM
  curl -fsSL "$url" | gpg --dearmor >"$tmp"

  if install_file_if_changed "$tmp" "$dest" 0644; then
    trap - EXIT HUP INT TERM
    cleanup
    return 0
  fi

  trap - EXIT HUP INT TERM
  cleanup
  return 1
}

sync_apt_source() {
  dest="$1"
  source_line="$2"
  tmp="$(mktemp)"

  cleanup() {
    rm -f "$tmp"
  }

  trap cleanup EXIT HUP INT TERM
  printf '%s\n' "$source_line" >"$tmp"

  if install_file_if_changed "$tmp" "$dest" 0644; then
    trap - EXIT HUP INT TERM
    cleanup
    return 0
  fi

  trap - EXIT HUP INT TERM
  cleanup
  return 1
}

install_google_cloud_repo() {
  apt_install apt-transport-https ca-certificates curl gnupg
  repo_changed=0

  if sync_keyring \
    https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    /usr/share/keyrings/cloud.google.gpg; then
    repo_changed=1
  fi

  if sync_apt_source \
    /etc/apt/sources.list.d/google-cloud-sdk.list \
    "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main"; then
    repo_changed=1
  fi

  if [ "$repo_changed" -eq 1 ]; then
    sudo apt-get update
  fi
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
  repo_changed=0

  if sync_keyring \
    "https://download.docker.com/linux/${ID}/gpg" \
    /etc/apt/keyrings/docker.gpg; then
    repo_changed=1
  fi

  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  if sync_apt_source \
    /etc/apt/sources.list.d/docker.list \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable"; then
    repo_changed=1
  fi

  if [ "$repo_changed" -eq 1 ]; then
    sudo apt-get update
  fi
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
