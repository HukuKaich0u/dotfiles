# Ubuntu Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** UTM 上の Ubuntu で、clone 後 1 コマンドで CLI 中心の開発環境と dotfiles 適用まで完了させる

**Architecture:** 既存 `install.sh` は link 専任のまま維持。新規 `scripts/bootstrap-ubuntu.sh` を外側に置き、Ubuntu 判定、`apt` 導入、`codex` 導入、`install.sh` 実行、最後の案内を担当させる。

**Tech Stack:** Bash, apt, npm, Codex CLI, existing dotfiles installer

---

## Chunk 1: bootstrap script

### Task 1: script 骨格追加

**Files:**
- Create: `scripts/bootstrap-ubuntu.sh`

- [ ] Step 1: failing check 方針整理
Expected:
`set -euo pipefail`、Ubuntu 判定、必要 command 判定、package list、`install_codex()`、`main()` を持つ骨格を決める

- [ ] Step 2: 最小実装を書く

```bash
#!/usr/bin/env bash
set -euo pipefail

PACKAGES=(
  git curl zsh tmux neovim ripgrep fd-find fzf unzip build-essential nodejs npm
)
```

- [ ] Step 3: Ubuntu 判定と package install 実装
Run: `bash -n scripts/bootstrap-ubuntu.sh`
Expected: PASS

- [ ] Step 4: `install_codex()` 実装

```bash
if command -v codex >/dev/null 2>&1; then
  return
fi
npm install -g @openai/codex
command -v codex >/dev/null 2>&1
```

- [ ] Step 5: `./install.sh` 呼び出しと shell 切替案内を実装
Run: `bash -n scripts/bootstrap-ubuntu.sh`
Expected: PASS

- [ ] Step 6: commit

```bash
git add scripts/bootstrap-ubuntu.sh
git commit -m "feat: add ubuntu bootstrap script"
```

## Chunk 2: verification and fit with repo

### Task 2: script の repo 適合確認

**Files:**
- Modify: `scripts/bootstrap-ubuntu.sh`
- Check: `install.sh`

- [ ] Step 1: `install.sh` 呼び出し path を repo root 基準で固定
Expected: script をどこから実行しても repo 内 `install.sh` を呼べる

- [ ] Step 2: 出力文を短く整える
Expected: 失敗時メッセージが具体的、成功時に次手順が見える

- [ ] Step 3: syntax check
Run: `bash -n scripts/bootstrap-ubuntu.sh install.sh`
Expected: PASS

- [ ] Step 4: dry-read
Run: `sed -n '1,240p' scripts/bootstrap-ubuntu.sh`
Expected: Ubuntu 判定 → apt → codex → install.sh → final hints の順

- [ ] Step 5: commit

```bash
git add scripts/bootstrap-ubuntu.sh
git commit -m "chore: refine ubuntu bootstrap flow"
```

## Chunk 3: manual verification

### Task 3: fresh Ubuntu 手順の確認

**Files:**
- Check: `scripts/bootstrap-ubuntu.sh`
- Check: `docs/superpowers/specs/2026-04-22-ubuntu-bootstrap-design.md`

- [ ] Step 1: 想定実行コマンド確認
Run: `./scripts/bootstrap-ubuntu.sh`
Expected: Ubuntu でのみ進行、非 Ubuntu では明確に停止

- [ ] Step 2: 成功後確認項目を実行
Run: `zsh --version`
Expected: PASS

- [ ] Step 3: tmux 確認
Run: `tmux -V`
Expected: PASS

- [ ] Step 4: nvim 確認
Run: `nvim --version`
Expected: PASS

- [ ] Step 5: codex 確認
Run: `codex --help`
Expected: PASS

- [ ] Step 6: shell 読込確認
Run: `zsh -i -c exit`
Expected: 即死しない

## Unresolved Questions

- なし
