# zsh PATH Responsibility Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `zsh.nix` に PATH 変更処理を一元化し、`env.zsh` を PATH 非変更の環境調整専用に整理する

**Architecture:** `zsh.nix` で `brew shellenv`、`nix-daemon.sh`、base PATH、`cargo`、`pnpm`、`conda`、`gcloud`、`~/.local/bin/env`、`local.zsh` の PATH 変更または PATH 変更の呼び出し元をすべて管理する。`env.zsh` からは PATH 変更をすべて外し、履歴、既存の非 PATH 環境変数、`gcloud` completion だけを残す。今回は環境変数まわりの取捨選択は行わず、既存挙動維持を優先する。基礎レイヤでは `nix > homebrew` を維持する。

**Tech Stack:** Nix, Home Manager, zsh, POSIX shell, grep

---

## Chunk 1: path ownership

### Task 1: `zsh.nix` に PATH 骨格を寄せる

**Files:**
- Modify: `.config/nix/home-manager/zsh.nix`
- Modify: `.config/nix/home-manager/zsh/env.zsh`
- Delete: `.config/nix/home-manager/zsh/homebrew.zsh`
- Check: `docs/superpowers/specs/2026-05-01-zsh-path-responsibility-design.md`

- [ ] **Step 1: 現状の PATH 追加箇所を確認する**
Run: `rg -n "homebrew\\.zsh|shellenv|PATH|cargo|PNPM_HOME|conda|gcloud|nix-daemon" .config/nix/home-manager/zsh.nix .config/nix/home-manager/zsh/env.zsh .config/nix/home-manager/zsh/homebrew.zsh`
Expected: Homebrew, cargo, pnpm, conda, gcloud を含む PATH 変更経路が複数ファイルに散っていることが見える

- [ ] **Step 2: `zsh.nix` に PATH 変更処理を集約する**
Expected: `brew shellenv`、`nix-daemon.sh`、base PATH、`cargo`、`pnpm`、`conda`、`gcloud` の PATH 変更が `zsh.nix` だけに集まる

- [ ] **Step 3: 基礎レイヤで `nix > homebrew` を明示する**
Expected: `brew shellenv` を先に、`nix-daemon.sh` を後に読む順序が残る。コード上でも優先意図が読める

- [ ] **Step 4: `env.zsh` から PATH 変更をすべて削除する**
Expected: `env.zsh` から `PATH=`、PATH 変更の `source`、`GOPATH` 由来の PATH 追加が消える

- [ ] **Step 5: `env.zsh` を動的調整専用に整える**
Expected: `ZSH_STATE_DIR`、`HISTFILE`、`JAVA_HOME`、`PNPM_HOME`、`CPLUS_INCLUDE_PATH`、`gcloud` completion など既存の非 PATH 環境調整は維持される

- [ ] **Step 6: `homebrew.zsh` を削除し、参照も消す**
Expected: runtime 配下に `homebrew.zsh` が不要になり、`zsh.nix` からも参照が消える

- [ ] **Step 7: diff を確認する**
Run: `git diff -- .config/nix/home-manager/zsh.nix .config/nix/home-manager/zsh/env.zsh .config/nix/home-manager/zsh/homebrew.zsh`
Expected: PATH 関連は `zsh.nix` に集中し、`env.zsh` は PATH 非変更ファイルになる

## Chunk 2: test updates

### Task 2: 責務整理をテストに反映する

**Files:**
- Modify: `tests/zsh_nix_migration_test.sh`
- Modify: `tests/env_portability_test.sh`

- [ ] **Step 1: `zsh_nix_migration_test.sh` に新しい責務境界を反映する**
Expected: `zsh.nix` が PATH 変更処理を一元化していること、`homebrew.zsh` が不要になったこと、`nix-daemon.sh` 読込が維持されることを確認する

- [ ] **Step 2: `env_portability_test.sh` を責務整理後の期待値に合わせる**
Expected: `env.zsh` 単体 source で machine-specific path leak がないことと、履歴・既存の非 PATH 環境変数初期化が保たれることを確認する

- [ ] **Step 3: `env.zsh` が PATH を変更しないことを検証する assertion を追加する**
Expected: PATH 変更の再流入をテストで防げる

- [ ] **Step 4: `homebrew.zsh` が消えたことを検証する assertion を追加する**
Expected: PATH 入口が再分散しない

- [ ] **Step 5: 変更した test ファイルの diff を確認する**
Run: `git diff -- tests/zsh_nix_migration_test.sh tests/env_portability_test.sh`
Expected: 新しい責務境界を表す assertion だけが増える

## Chunk 3: verification

### Task 3: shell 挙動を確認する

**Files:**
- Check: `.config/nix/home-manager/zsh.nix`
- Check: `.config/nix/home-manager/zsh/env.zsh`
- Test: `tests/zsh_nix_migration_test.sh`
- Test: `tests/env_portability_test.sh`

- [ ] **Step 1: zsh migration test を実行する**
Run: `./tests/zsh_nix_migration_test.sh`
Expected: `zsh nix migration tests passed`

- [ ] **Step 2: env portability test を実行する**
Run: `./tests/env_portability_test.sh`
Expected: exit code 0

- [ ] **Step 3: login interactive shell の PATH 順序を確認する**
Run: `zsh -lic 'print -l ${(s/:/)PATH}'`
Expected: Nix 系 path が Homebrew 系 path より前に出る

- [ ] **Step 4: 代表コマンドの解決順を確認する**
Run: `zsh -lic 'command -v nix; command -v brew; command -v cargo; command -v pnpm; command -v conda; command -v gcloud'`
Expected: 使っているツール群が従来どおり解決でき、`PATH` 調整で壊れていない

- [ ] **Step 5: commit**
```bash
git add .config/nix/home-manager/zsh.nix .config/nix/home-manager/zsh/env.zsh tests/zsh_nix_migration_test.sh tests/env_portability_test.sh docs/superpowers/plans/2026-05-01-zsh-path-responsibility.md
git rm .config/nix/home-manager/zsh/homebrew.zsh
git commit -m "refactor(zsh): centralize path management"
```

## Unresolved Questions

- なし
