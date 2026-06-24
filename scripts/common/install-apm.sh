#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/common/install-apm.sh

Install APM with the official macOS / Linux installer if it is not already available on PATH.
EOF
}

main() {
  if [ "$#" -ne 0 ]; then
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "install-apm.sh does not accept arguments" >&2
        usage >&2
        exit 1
        ;;
    esac
  fi

  local_bin="${HOME}/.local/bin"
  PATH="${local_bin}:${HOME}/bin:${PATH}"
  export PATH

  if existing_apm="$(command -v apm 2>/dev/null)"; then
    echo "apm already installed at $existing_apm, skipping"
    exit 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required before installing APM. Install curl first, then rerun this script." >&2
    exit 1
  fi

  if ! command -v sh >/dev/null 2>&1; then
    echo "sh is required before installing APM. Install a POSIX shell first, then rerun this script." >&2
    exit 1
  fi

  install_dir="${HOME}/.cache/apm"
  install_script="${install_dir}/install.sh"

  mkdir -p "$install_dir"
  curl -fsSL https://aka.ms/apm-unix -o "$install_script"
  sh "$install_script"

  if installed_apm="$(command -v apm 2>/dev/null)"; then
    echo "APM installed at $installed_apm"
    exit 0
  fi

  for candidate in \
    "${HOME}/.local/bin/apm" \
    "${HOME}/bin/apm"
  do
    if [ -x "$candidate" ]; then
      echo "APM was installed at $candidate, but it is not on PATH. Open a new zsh session or update PATH, then rerun this script." >&2
      exit 1
    fi
  done

  echo "APM install completed, but 'apm' is still not on PATH. Open a new zsh session or verify your PATH, then rerun this script." >&2
  exit 1
}

main "$@"
