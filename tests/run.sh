#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
failed=""

for test_script in "$repo_root"/tests/*_test.sh; do
  name="$(basename "$test_script")"
  echo "==> $name"
  if sh "$test_script"; then
    echo "PASS: $name"
  else
    echo "FAIL: $name"
    failed="$failed $name"
  fi
done

if command -v nvim >/dev/null 2>&1; then
  for test_lua in "$repo_root"/tests/*_test.lua; do
    [ -f "$test_lua" ] || continue
    name="$(basename "$test_lua")"
    echo "==> $name"
    if nvim --headless -l "$test_lua"; then
      echo "PASS: $name"
    else
      echo "FAIL: $name"
      failed="$failed $name"
    fi
  done
else
  echo "skip: nvim not found, lua tests skipped"
fi

if [ -n "$failed" ]; then
  echo ""
  echo "failed:$failed"
  exit 1
fi

echo ""
echo "all tests passed"
