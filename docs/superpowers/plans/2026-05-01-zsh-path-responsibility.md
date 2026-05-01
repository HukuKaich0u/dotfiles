# zsh PATH Responsibility Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `zsh.nix` に zsh の環境初期化を一元化し、分割 shell file をなくす

**Architecture:** `zsh.nix` で `brew shellenv`、`nix-daemon.sh`、base PATH、`cargo`、`pnpm`、`conda`、`gcloud`、`~/.local/bin/env`、`local.zsh` の PATH 変更または PATH 変更の呼び出し元に加え、`ZSH_STATE_DIR`、`HISTFILE`、`JAVA_HOME`、`PNPM_HOME`、`CPLUS_INCLUDE_PATH`、`gcloud` completion も管理する。`env.zsh` と `homebrew.zsh` は削除する。基礎レイヤでは `nix > homebrew` を維持する。

**Tech Stack:** Nix, Home Manager, zsh, POSIX shell, grep

---

## Chunk 1: path ownership

### Task 1: `zsh.nix` に PATH 骨格を寄せる

**Files:**
- Modify: `.config/nix/home-manager/zsh.nix`
- Delete: `.config/nix/home-manager/zsh/env.zsh`
- Delete: `.config/nix/home-manager/zsh/homebrew.zsh`
- Check: `docs/superpowers/specs/2026-05-01-zsh-path-responsibility-design.md`

- [ ] **Step 1: 現状の PATH 追加箇所を確認する**
Run: `rg -n "homebrew\\.zsh|shellenv|PATH|cargo|PNPM_HOME|conda|gcloud|nix-daemon|HISTFILE|JAVA_HOME|CPLUS_INCLUDE_PATH" .config/nix/home-manager/zsh.nix .config/nix/home-manager/zsh/env.zsh .config/nix/home-manager/zsh/homebrew.zsh`
Expected: PATH と非 PATH の環境初期化が複数ファイルに散っていることが見える

- [ ] **Step 2: `zsh.nix` に環境初期化を集約する**
Expected: `brew shellenv`、`nix-daemon.sh`、base PATH、`cargo`、`pnpm`、`conda`、`gcloud`、履歴、非 PATH の環境変数初期化が `zsh.nix` だけに集まる

- [ ] **Step 3: 基礎レイヤで `nix > homebrew` を明示する**
Expected: `brew shellenv` を先に、`nix-daemon.sh` を後に読む順序が残る。コード上でも優先意図が読める

- [ ] **Step 4: `env.zsh` の役割を `zsh.nix` に移す**
Expected: `ZSH_STATE_DIR`、`HISTFILE`、`JAVA_HOME`、`PNPM_HOME`、`CPLUS_INCLUDE_PATH`、`gcloud` completion が `zsh.nix` へ移る

- [ ] **Step 5: `env.zsh` と `homebrew.zsh` を削除し、参照も消す**
Expected: runtime 配下に `env.zsh` と `homebrew.zsh` が不要になり、`zsh.nix` からの参照も消える

- [ ] **Step 6: diff を確認する**
Run: `git diff -- .config/nix/home-manager/zsh.nix .config/nix/home-manager/zsh/env.zsh .config/nix/home-manager/zsh/homebrew.zsh`
Expected: zsh の環境初期化が `zsh.nix` に集中し、分割 shell file が消える

## Chunk 2: test updates

### Task 2: 責務整理をテストに反映する

**Files:**
- Modify: `tests/zsh_nix_migration_test.sh`
- Delete: `tests/env_portability_test.sh`

- [ ] **Step 1: `zsh_nix_migration_test.sh` に新しい責務境界を反映する**
Expected: `zsh.nix` が PATH と非 PATH の環境初期化を一元化していること、`env.zsh` と `homebrew.zsh` が不要になったこと、`nix-daemon.sh` 読込が維持されることを確認する

- [ ] **Step 2: obsolete test を削除する**
Expected: `env_portability_test.sh` は不要になり、単一ファイル構成に合わない test が残らない

- [ ] **Step 3: `zsh_nix_migration_test.sh` に `env.zsh` 廃止の assertion を追加する**
Expected: 分割 file の再導入をテストで防げる

- [ ] **Step 4: `zsh_nix_migration_test.sh` に非 PATH env 初期化の assertion を追加する**
Expected: `JAVA_HOME`、`HISTFILE`、`PNPM_HOME` などが再び別ファイルへ逃げない

- [ ] **Step 5: 変更した test ファイルの diff を確認する**
Run: `git diff -- tests/zsh_nix_migration_test.sh tests/env_portability_test.sh`
Expected: 新しい責務境界を表す assertion だけが増える

## Chunk 3: verification

### Task 3: shell 挙動を確認する

**Files:**
- Check: `.config/nix/home-manager/zsh.nix`
- Test: `tests/zsh_nix_migration_test.sh`

- [ ] **Step 1: zsh migration test を実行する**
Run: `./tests/zsh_nix_migration_test.sh`
Expected: `zsh nix migration tests passed`

- [ ] **Step 2: login interactive shell で代表 env var を確認する**
Run: `zsh -lic 'printf "JAVA_HOME=%s\nPNPM_HOME=%s\nHISTFILE=%s\n" "${JAVA_HOME-}" "${PNPM_HOME-}" "${HISTFILE-}"'`
Expected: 既存環境と同じ変数が解決できる

- [ ] **Step 3: login interactive shell の PATH 順序を確認する**
Run: `zsh -lic 'print -l ${(s/:/)PATH}'`
Expected: Nix 系 path が Homebrew 系 path より前に出る

- [ ] **Step 4: 代表コマンドの解決順を確認する**
Run: `zsh -lic 'command -v nix; command -v brew; command -v cargo; command -v pnpm; command -v conda; command -v gcloud'`
Expected: 使っているツール群が従来どおり解決でき、`PATH` 調整で壊れていない

- [ ] **Step 5: commit**
```bash
git add .config/nix/home-manager/zsh.nix tests/zsh_nix_migration_test.sh docs/superpowers/specs/2026-05-01-zsh-path-responsibility-design.md docs/superpowers/plans/2026-05-01-zsh-path-responsibility.md
git rm .config/nix/home-manager/zsh/env.zsh .config/nix/home-manager/zsh/homebrew.zsh tests/env_portability_test.sh
git commit -m "refactor(zsh): inline zsh environment setup"
```

## Unresolved Questions

- なし
