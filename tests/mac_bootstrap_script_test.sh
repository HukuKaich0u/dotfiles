#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
install_homebrew_script="$repo_root/scripts/install-homebrew.sh"
apply_nix_darwin_script="$repo_root/scripts/apply-nix-darwin.sh"
setup_mac_script="$repo_root/scripts/setup-mac.sh"
scripts_readme="$repo_root/scripts/README.md"
nix_readme="$repo_root/nix/README.md"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"

  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_file_exists() {
  path="$1"
  message="$2"

  if [ ! -f "$path" ]; then
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

section_between() {
  file="$1"
  start_heading="$2"
  end_heading="$3"

  awk -v start="$start_heading" -v end="$end_heading" '
    $0 == start { in_section = 1; next }
    $0 == end { in_section = 0 }
    in_section { print }
  ' "$file"
}

create_temp_dir() {
  mktemp -d "${TMPDIR:-/tmp}/mac-script-test.XXXXXX"
}

make_executable() {
  chmod +x "$1"
}

test_mac_scripts_exist_and_document_guards() {
  assert_file_exists "$install_homebrew_script" "install-homebrew.sh must exist"
  assert_file_exists "$apply_nix_darwin_script" "apply-nix-darwin.sh must exist"
  assert_file_exists "$setup_mac_script" "setup-mac.sh must exist"

  assert_contains "$install_homebrew_script" 'command -v brew' \
    "install-homebrew.sh must skip when brew already exists"
  assert_contains "$install_homebrew_script" 'brew already installed, skipping' \
    "install-homebrew.sh must explain the brew skip path"
  assert_contains "$apply_nix_darwin_script" 'command -v nix' \
    "apply-nix-darwin.sh must check for nix first"
  assert_contains "$apply_nix_darwin_script" 'command -v darwin-rebuild' \
    "apply-nix-darwin.sh must check for darwin-rebuild first"
  assert_contains "$apply_nix_darwin_script" 'darwin-rebuild switch --flake ./nix#KokiAoyagi' \
    "apply-nix-darwin.sh must apply the KokiAoyagi flake target"
}

test_setup_mac_order() {
  (
    tmpdir="$(create_temp_dir)"
    trap 'rm -rf "$tmpdir"' EXIT HUP INT TERM

    scripts_dir="$tmpdir/scripts"
    log_file="$tmpdir/calls.log"
    mkdir -p "$scripts_dir"

    cp "$setup_mac_script" "$scripts_dir/setup-mac.sh"
    make_executable "$scripts_dir/setup-mac.sh"

    cat >"$scripts_dir/install-homebrew.sh" <<EOF
#!/bin/sh
echo "install-homebrew:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/install-homebrew.sh"

    cat >"$scripts_dir/apply-nix-darwin.sh" <<EOF
#!/bin/sh
echo "apply-nix-darwin:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/apply-nix-darwin.sh"

    cat >"$scripts_dir/link-dotfiles.sh" <<EOF
#!/bin/sh
echo "link-dotfiles:\$*" >>"$log_file"
EOF
    make_executable "$scripts_dir/link-dotfiles.sh"

    HOME="$tmpdir/home" PATH="/bin:/usr/bin" /bin/sh "$scripts_dir/setup-mac.sh"

    assert_file_equals "$log_file" \
"install-homebrew:
apply-nix-darwin:
link-dotfiles:" \
      "setup-mac.sh should call Homebrew, nix-darwin, then link-dotfiles in order"
  )
}

test_mac_readmes() {
  mac_shortest_path_section="$(section_between "$scripts_readme" '## macOS 最短手順' '## Script 一覧')"

  assert_contains "$scripts_readme" '## macOS 最短手順' \
    "scripts/README.md must document the macOS shortest path"
  assert_contains "$scripts_readme" './scripts/setup-mac.sh' \
    "scripts/README.md must point macOS bootstrap to setup-mac.sh"
  assert_contains "$scripts_readme" 'install-homebrew.sh' \
    "scripts/README.md must describe install-homebrew.sh"
  assert_contains "$scripts_readme" 'apply-nix-darwin.sh' \
    "scripts/README.md must describe apply-nix-darwin.sh"
  if ! printf '%s\n' "$mac_shortest_path_section" | grep -Fq 'gcloud init'; then
    echo "scripts/README.md macOS shortest-path section must include the gcloud init manual step when gcloud is used"
    exit 1
  fi

  assert_contains "$nix_readme" '## macOS Shortest Path' \
    "nix/README.md must document the macOS shortest path"
  assert_contains "$nix_readme" './scripts/setup-mac.sh' \
    "nix/README.md must point macOS bootstrap to setup-mac.sh"
  assert_contains "$nix_readme" 'darwin-rebuild switch --flake ./nix#KokiAoyagi' \
    "nix/README.md must document the nix-darwin apply command"
}

test_mac_scripts_exist_and_document_guards
test_setup_mac_order
test_mac_readmes

echo "mac bootstrap script test passed"
