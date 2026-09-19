#!/usr/bin/env python3
"""Render shared Markdown instructions for Claude and Codex into a fresh directory."""

import argparse
from pathlib import Path
import re


def read_body(path):
    text = path.read_text(encoding="utf-8")
    if text.startswith("---\n"):
        _, separator, text = text[4:].partition("\n---\n")
        if not separator:
            raise ValueError(f"Unclosed frontmatter: {path}")
    return text.lstrip("\n")


def nest_headings(body):
    lines = []
    fence = None
    for line in body.splitlines():
        marker = re.match(r"^ {0,3}(`{3,}|~{3,})(.*)$", line)
        if fence is None:
            if marker:
                fence = marker[1]
            elif re.match(r"^#{1,5} ", line):
                line = "#" + line
        elif marker and marker[1][0] == fence[0] and len(marker[1]) >= len(fence) and not marker[2].strip():
            fence = None
        lines.append(line)
    return "\n".join(lines).rstrip("\n") + "\n"


def render(source, output):
    files = sorted(source.glob("*.md"))
    if not files:
        raise ValueError(f"No instructions found: {source}")
    bodies = [(path.name, read_body(path)) for path in files]
    output.mkdir(parents=True, exist_ok=True)
    if any(output.iterdir()):
        raise ValueError(f"Output directory must be empty: {output}")
    rules = output / ".claude/rules"
    rules.mkdir(parents=True)
    codex = output / ".codex"
    codex.mkdir()
    sections = [
        "# AGENTS.md\n\n"
        "<!-- Generated from dotfiles/agents/instructions/*.md by Nix. Edit the source files. -->\n\n"
        "Claude と共有する instructions。\n"
    ]
    for name, body in bodies:
        (rules / name).write_text(body, encoding="utf-8")
        sections.append(f"\n\n## {Path(name).stem}\n\n\n{nest_headings(body)}")
    (codex / "AGENTS.md").write_text("".join(sections), encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    render(args.source, args.output)
