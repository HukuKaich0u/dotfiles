# starship Docker Context Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `starship` の Docker 表示を、Docker を使う repo とコンテナ内作業でだけ出るようにする

**Architecture:** built-in `docker_context` の静的検知を使わず、`.config/starship.toml` の Docker 表示を `custom.docker_context` に置き換える。repo root 配下の Docker 痕跡とコンテナ内実行を shell command で判定し、表示文言は `docker context show` を使って既存の見た目を保つ。

**Tech Stack:** Starship, TOML, zsh, git, docker

---

## Chunk 1: prompt wiring

### Task 1: Docker 表示を custom module へ差し替える

**Files:**
- Modify: `.config/starship.toml`
- Check: `docs/superpowers/specs/2026-04-30-starship-docker-design.md`

- [ ] Step 1: 既存 `format` 内の Docker 表示位置を確認する
Run: `sed -n '1,120p' .config/starship.toml`
Expected: `git_status` の後ろに Docker 表示がある

- [ ] Step 2: built-in `docker_context` を format から外し、同位置に `custom.docker_context` を入れる
Expected: 表示順は維持され、描画責務だけ custom に移る

- [ ] Step 3: `[custom.docker_context]` を追加し、repo root 配下の Docker 痕跡またはコンテナ内実行を判定する command を書く
Expected: `Dockerfile` `Containerfile` `compose*.yml` `.devcontainer` `docker/` を見つけた時だけ `docker context show` の結果を返す

- [ ] Step 4: 既存の青系スタイルと icon を custom module 側へ移す
Expected: 見た目は現状とほぼ同じ

## Chunk 2: verification

### Task 2: 表示条件が狙い通りか確認する

**Files:**
- Check: `.config/starship.toml`

- [ ] Step 1: Docker 痕跡あり repo で module 単体出力を確認する
Run: `starship module custom.docker_context -p /path/to/docker-repo`
Expected: context 名を含む表示が出る

- [ ] Step 2: Docker 痕跡なし repo で module 単体出力を確認する
Run: `starship module custom.docker_context -p /path/to/non-docker-repo`
Expected: 何も出ない

- [ ] Step 3: subdirectory 配下にだけ Docker 痕跡がある repo で確認する
Run: `starship module custom.docker_context -p /path/to/nested-docker-repo`
Expected: repo root からでも表示が出る

- [ ] Step 4: `starship explain` または対話 shell で prompt 全体の崩れを確認する
Run: `starship explain`
Expected: custom module が認識され、他 module の並びが壊れていない

- [ ] Step 5: commit
```bash
git add .config/starship.toml docs/superpowers/plans/2026-04-30-starship-docker.md
git commit -m "feat(starship): refine docker context detection"
```

## Unresolved Questions

- なし
