#!/bin/sh

# 実際の Starship を使い、狭い Terminal での折り返しと長いブランチ名を検証する。
set -eu

for tool in starship nix-instantiate python3 git; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "SKIP: $tool not found"
    exit 0
  fi
done

repo_root="$(CDPATH='' cd -- "$(dirname "$0")/.." && pwd)"
python3 - "$repo_root" <<'PY'
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import unicodedata

module = Path(sys.argv[1]) / "nix/modules/home/programs/starship.nix"
settings = json.loads(subprocess.check_output([
    "nix-instantiate", "--eval", "--strict", "--json", "--expr",
    f"(import {json.dumps(str(module))} {{}}).programs.starship.settings",
]))

# この設定が使う TOML の scalar と table を出力する。
def toml_table(table):
    return "\n".join(f"{key} = {json.dumps(value, ensure_ascii=False)}"
                     for key, value in table.items() if not isinstance(value, dict))

with tempfile.TemporaryDirectory(prefix="starship-prompt-") as tmp:
    root = Path(tmp).resolve()
    config = root / "starship.toml"
    config.write_text(toml_table(settings) + "\n" + "\n".join(
        f"[{name}]\n{toml_table(value)}"
        for name, value in settings.items() if isinstance(value, dict)
    ))
    project = root / "nested" / "workspace" / "project"
    project.mkdir(parents=True)
    subprocess.run(["git", "init", "-q", "-b", "feature/a-very-long-branch-name-for-terminal-resizing", str(project)], check=True)
    (project / "example.txt").write_text("untracked\n")
    env = dict(os.environ, PWD=str(project), STARSHIP_CONFIG=str(config), STARSHIP_SHELL="nu",
               STARSHIP_CACHE=str(root / "cache"))
    for key in ("SSH_CONNECTION", "SSH_CLIENT", "SSH_TTY", "GIT_DIR", "GIT_WORK_TREE"):
        env.pop(key, None)

    def prompt(*args):
        result = subprocess.run(["starship", "prompt", "--terminal-width", "40", *args],
                                cwd=project, env=env, text=True, capture_output=True, check=True)
        assert not result.stderr, result.stderr
        plain = re.sub(r"\x1b\[[0-9;]*m", "", result.stdout)
        return result.stdout, plain

    success, plain = prompt("--status", "0", "--cmd-duration", "10")
    assert "\n" not in plain, f"Prompt must stay on the input line: {plain!r}"
    width = sum(2 if unicodedata.east_asian_width(c) in ("W", "F") else 1 for c in plain)
    assert width < 40, f"Prompt wraps at 40 columns ({width}): {plain!r}"
    assert "project" in plain and "feature/" in plain, plain
    assert "workspace" not in plain and "terminal-resizing" not in plain, plain
    assert "?" in plain, f"Untracked changes must remain visible: {plain!r}"
    assert plain.endswith("❯ "), plain
    failed, _ = prompt("--status", "1")
    assert failed != success, "Failed commands must change the prompt indicator"
    _, slow = prompt("--cmd-duration", "2300")
    assert "2s" in slow and "2s" not in plain, (plain, slow)
    _, jobs = prompt("--jobs", "1")
    assert "&" in jobs, f"Background jobs must remain visible: {jobs!r}"
    print(f"OK: compact prompt, branch truncation, Git status, error, duration, jobs ({width} columns)")
PY
