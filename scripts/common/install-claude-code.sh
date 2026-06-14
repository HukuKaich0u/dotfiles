#!/bin/sh

set -eu

usage() {
  cat <<'EOF'
Usage: ./scripts/common/install-claude-code.sh

Install the latest native Claude Code build if it is not already available on PATH.
EOF
}

is_cmux_bundled_claude() {
  case "$1" in
    */cmux.app/Contents/Resources/bin/claude)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

main() {
  if [ "$#" -ne 0 ]; then
    case "$1" in
      -h|--help)
        usage
        exit 0
        ;;
      *)
        echo "install-claude-code.sh does not accept arguments" >&2
        usage >&2
        exit 1
        ;;
    esac
  fi

  native_bin="${HOME}/.local/bin"
  PATH="${native_bin}:${PATH}"
  export PATH

  if existing_claude="$(command -v claude 2>/dev/null)"; then
    if ! is_cmux_bundled_claude "$existing_claude"; then
      echo "claude already installed at $existing_claude, skipping"
      exit 0
    fi

    echo "found cmux-bundled claude at $existing_claude, continuing with native Claude Code install"
  fi

  if ! command -v curl >/dev/null 2>&1; then
    echo "curl is required before installing Claude Code. Install curl first, then rerun this script." >&2
    exit 1
  fi

  if ! command -v bash >/dev/null 2>&1; then
    echo "bash is required before installing Claude Code. Install bash first, then rerun this script." >&2
    exit 1
  fi

  install_dir="${HOME}/.cache/claude-code"
  install_script="${install_dir}/install.sh"
  native_claude="${native_bin}/claude"

  mkdir -p "$install_dir"
  curl -fsSL https://claude.ai/install.sh -o "$install_script"
  bash -s latest < "$install_script"

  if ! installed_claude="$(command -v claude 2>/dev/null)"; then
    if [ -x "$native_claude" ]; then
      echo "Claude Code native install exists at $native_claude, but it is not on PATH. Open a new zsh session or put $HOME/.local/bin on PATH, then rerun this script." >&2
      exit 1
    fi

    echo "Claude Code install completed, but 'claude' is still not on PATH. Open a new zsh session or verify your PATH, then rerun this script." >&2
    exit 1
  fi

  if is_cmux_bundled_claude "$installed_claude"; then
    if [ -x "$native_claude" ]; then
      echo "Claude Code native install exists at $native_claude, but PATH still resolves claude to the cmux-bundled shim: $installed_claude. Put $HOME/.local/bin before cmux in PATH, open a new zsh session, then rerun this script." >&2
      exit 1
    fi

    echo "Claude Code install completed, but only the cmux-bundled claude is visible on PATH: $installed_claude. Put $HOME/.local/bin before cmux in PATH, open a new zsh session, then rerun this script." >&2
    exit 1
  fi
}

main "$@"
