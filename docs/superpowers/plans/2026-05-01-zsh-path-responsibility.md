# zsh PATH Responsibility Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `zsh.nix` に PATH 骨格と読み込み順を集約し、`env.zsh` を動的な微調整専用に整理する

**Architecture:** `zsh.nix` で `homebrew.zsh` と `nix-daemon.sh` の読込順、および基礎 PATH レイヤを管理する。`env.zsh` からは `homebrew` の再読込と `~/go/bin` を外し、履歴、既存の環境変数初期化、`conda`、`gcloud`、ローカル override をそのまま残す。今回は環境変数まわりの取捨選択は行わず、既存挙動維持を優先する。基礎レイヤでは `nix > homebrew` を維持する。

**Tech Stack:** Nix, Home Manager, zsh, POSIX shell, grep

---

## Chunk 1: path ownership

### Task 1: `zsh.nix` に PATH 骨格を寄せる

**Files:**
- Modify: `.config/nix/home-manager/zsh.nix`
- Modify: `.config/nix/home-manager/zsh/env.zsh`
- Check: `docs/superpowers/specs/2026-05-01-zsh-path-responsibility-design.md`

- [ ] **Step 1: 現状の PATH 追加箇所を確認する**
Run: `rg -n "homebrew\\.zsh|PATH|GOPATH|PNPM_HOME|JAVA_HOME|nix-daemon" .config/nix/home-manager/zsh.nix .config/nix/home-manager/zsh/env.zsh`
Expected: `homebrew.zsh` の二重読込、`env.zsh` 側の PATH 操作、`nix-daemon.sh` 読込位置が見える

- [ ] **Step 2: `zsh.nix` に基礎 PATH 追加 helper とレイヤ順を定義する**
Expected: `profileExtra` または `initContent` 内で、`homebrew.zsh` 読込後に `nix-daemon.sh` を読み、さらに基礎 PATH を追加する構成になる

- [ ] **Step 3: 基礎レイヤで `nix > homebrew` を明示する**
Expected: `homebrew.zsh` を先に読み、`nix-daemon.sh` を後に読む順序が残る。コード上でも優先意図が読める

- [ ] **Step 4: `env.zsh` から `homebrew.zsh` の再読込と `~/go/bin` を削除する**
Expected: `env.zsh` 先頭の `source "$ZDOTDIR/homebrew.zsh"` が消え、`GOPATH` 由来の PATH 追加も消える

- [ ] **Step 5: `env.zsh` を動的調整専用に整える**
Expected: `ZSH_STATE_DIR`、`HISTFILE`、`JAVA_HOME`、`PNPM_HOME`、`conda`、`gcloud`、`~/.local/bin/env`、`local.zsh` など既存の環境変数・動的初期化は維持され、PATH 骨格だけが外に出る

- [ ] **Step 6: diff を確認する**
Run: `git diff -- .config/nix/home-manager/zsh.nix .config/nix/home-manager/zsh/env.zsh`
Expected: PATH 骨格が `zsh.nix` へ移り、`env.zsh` は補助的になる

## Chunk 2: test updates

### Task 2: 責務整理をテストに反映する

**Files:**
- Modify: `tests/zsh_nix_migration_test.sh`
- Modify: `tests/env_portability_test.sh`

- [ ] **Step 1: `zsh_nix_migration_test.sh` に新しい責務境界を反映する**
Expected: `zsh.nix` が PATH 骨格を持つこと、`env.zsh` が split file として残ること、`nix-daemon.sh` 読込が維持されることを確認する

- [ ] **Step 2: `env_portability_test.sh` を責務整理後の期待値に合わせる**
Expected: `env.zsh` 単体 source で machine-specific path leak がないことと、履歴・既存の環境変数初期化が保たれることを確認する

- [ ] **Step 3: `env.zsh` が `homebrew.zsh` を source しないことを検証する assertion を追加する**
Expected: 二重読込の再発をテストで防げる

- [ ] **Step 4: 変更した test ファイルの diff を確認する**
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
Run: `zsh -lic 'command -v nix; command -v brew; command -v pnpm'`
Expected: 3 つとも解決でき、`PATH` 調整で壊れていない

- [ ] **Step 5: commit**
```bash
git add .config/nix/home-manager/zsh.nix .config/nix/home-manager/zsh/env.zsh tests/zsh_nix_migration_test.sh tests/env_portability_test.sh docs/superpowers/plans/2026-05-01-zsh-path-responsibility.md
git commit -m "refactor(zsh): clarify path responsibilities"
```

## Unresolved Questions

- なし
