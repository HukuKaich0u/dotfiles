# tmux Nix Migration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `tmux` 本体・plugin・設定読込を `home-manager` 管理へ寄せ、TPM を除去しつつ現挙動を維持する

**Architecture:** `programs.tmux` で本体と plugin を宣言管理。設定本文は Nix 配下の `tmux.conf` 風ファイルへ移し、`home.nix` から `builtins.readFile` で読む。TPM 依存行と plugin path 直参照だけ差し替える。

**Tech Stack:** Nix, Home Manager, tmux, tmux plugins

---

## Chunk 1: config shape

### Task 1: Nix 配下へ tmux 設定を移す

**Files:**
- Create: `.config/nix/home-manager/tmux/tmux.conf`
- Check: `.config/tmux/tmux.conf`

- [ ] Step 1: 既存 `tmux.conf` をコピー
Run: `sed -n '1,260p' .config/tmux/tmux.conf`
Expected: 現設定全文を確認

- [ ] Step 2: TPM 依存行を削る
Expected: `TMUX_PLUGIN_MANAGER_PATH` と `run '~/.config/tmux/plugins/tpm/tpm'` が消える

- [ ] Step 3: plugin path 直参照を 1 箇所に絞る
Expected: `tmux-resurrect` の `save.sh` 呼び出しだけ要調整状態になる

## Chunk 2: home-manager wiring

### Task 2: `programs.tmux` を配線

**Files:**
- Modify: `.config/nix/home-manager/home.nix`
- Create: `.config/nix/home-manager/tmux/tmux.conf`

- [ ] Step 1: `programs.tmux.enable = true` を追加
Expected: `home-manager` 側で `tmux` を有効化

- [ ] Step 2: plugin 群を宣言
Expected: `catppuccin`, `sessionx`, `resurrect`, `continuum`, `battery`, `online-status` が並ぶ

- [ ] Step 3: `extraConfig = builtins.readFile ./tmux/tmux.conf;` を追加
Expected: 設定本文は別ファイル読込

- [ ] Step 4: `git` 既存設定と衝突しない形に整える
Run: `sed -n '1,240p' .config/nix/home-manager/home.nix`
Expected: `home.file` と `programs.tmux` の責務が明確

## Chunk 3: plugin runtime fix

### Task 3: Nix 管理後も plugin runtime を壊さない

**Files:**
- Modify: `.config/nix/home-manager/tmux/tmux.conf`
- Check: `.config/nix/home-manager/home.nix`

- [ ] Step 1: `resurrect` hook の script path を Nix 管理後に合わせる
Expected: `session-renamed` hook が有効なまま

- [ ] Step 2: plugin 固有 option を維持
Expected: `@sessionx-*` `@resurrect-*` `@continuum-*` `@catppuccin_*` `@online_*` が残る

- [ ] Step 3: 旧 TPM 前提参照が残っていないか確認
Run: `rg -n "tpm|TMUX_PLUGIN_MANAGER_PATH|plugins/tmux-" .config/nix/home-manager/tmux/tmux.conf`
Expected: 必要な runtime 参照以外ヒットしない

## Chunk 4: cleanup and verification

### Task 4: 未使用設定を整理し、動作確認する

**Files:**
- Modify: `install.sh`
- Check: `.config/tmux/tmux.conf`
- Check: `.config/nix/flake.nix`

- [ ] Step 1: `install.sh` が旧 `.config/tmux/tmux.conf` を配布しているなら止める
Expected: runtime source of truth が `home-manager` 側に一本化

- [ ] Step 2: Nix 評価確認
Run: `home-manager build --flake .config/nix#KokiAoyagi`
Expected: PASS

- [ ] Step 3: `tmux` 読込確認
Run: `tmux start-server \; source-file "$HOME/.config/tmux/tmux.conf"`
Expected: 明確な error なし

- [ ] Step 4: 手動機能確認
Expected: status line, `sessionx`, restore/save, mouse, copy mode が従来どおり

- [ ] Step 5: commit
```bash
git add .config/nix/home-manager/home.nix .config/nix/home-manager/tmux/tmux.conf install.sh
git commit -m "feat(nix): manage tmux with home-manager"
```

## Unresolved Questions

- なし
