# tmux Active Pane Visibility Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 選択中 pane の border を今より目立たせる

**Architecture:** `tmux` の pane border style 設定だけを変更する。既存 shell test に 1 つ assertion を足して、設定 drift を防ぐ。

**Tech Stack:** tmux, Home Manager, POSIX shell

---

## Chunk 1: test

### Task 1: active pane border の期待値を固定する

**Files:**
- Modify: `tests/tmux_nix_migration_test.sh`

- [ ] Step 1: active border style の assertion を追加
- [ ] Step 2: テストを実行して失敗を確認
Run: `./tests/tmux_nix_migration_test.sh`
Expected: FAIL because active border style expectation is not yet met

## Chunk 2: config

### Task 2: active pane border を強調する

**Files:**
- Modify: `.config/nix/home-manager/tmux/tmux.conf`

- [ ] Step 1: `pane-active-border-style` を高コントラスト + `bold` に変更
- [ ] Step 2: `tmux` source-file を実行して syntax error がないことを確認
Run: `tmux start-server \; source-file "$HOME/.config/tmux/tmux.conf"`
Expected: no error

## Chunk 3: verify

### Task 3: regression を確認する

**Files:**
- Check: `tests/tmux_nix_migration_test.sh`
- Check: `.config/nix/home-manager/tmux/tmux.conf`

- [ ] Step 1: テストを再実行して成功確認
Run: `./tests/tmux_nix_migration_test.sh`
Expected: PASS

## Unresolved Questions

- なし
