# AI CLI dotfiles 運用メモ

## 何を global dotfiles に置くか

この repo では、Codex と Claude Code のうち「どのマシンでも再現したい個人設定」だけを管理する。

対象:

- `~/.codex/config.toml`
- `~/.codex/AGENTS.md`
- `~/.codex/hooks.json`
- `~/.codex/hooks/*`
- `~/.claude/settings.json`
- `~/.claude/CLAUDE.md`
- `~/.claude/skills/*`
- `~/.agents/skills/*`

補足:

- `~/.codex/skills` は system skill 領域として扱う
- user skill は `~/.agents/skills` を一次置き場にする
- Claude Code にも同じ skill を使わせる場合は `~/.claude/skills/*` から `~/.agents/skills/*` を参照させる
- つまり、dotfiles で管理する共通 user skill は基本的に `~/.agents/skills/*` 側
- `superpowers` も repo 配下の `.agents/skills/superpowers` で管理する

## 何を project repo 側に置くか

repo 固有のルールや automation は、その repo 自身で管理する。

対象:

- Codex の `AGENTS.md`, `AGENTS.override.md`
- Codex の `.agents/skills/*`
- Codex の `.codex/hooks.json`, `.codex/hooks/*`
- Claude Code の `CLAUDE.md` または `.claude/CLAUDE.md`
- Claude Code の `.claude/settings.json`, `.claude/rules/*`, `.claude/skills/*`

## commit してはいけないもの

以下のような stateful file は dotfiles に入れない。

- auth 情報
- history / sessions
- SQLite DB
- cache / logs / debug 出力
- project trust 記録
- `~/.claude.json`

## instruction file の揃え方

global でも project でも、Codex と Claude Code に同じルールを読ませたい場合は、`AGENTS.md` を一次ソースにする。

推奨:

1. project root に `AGENTS.md` を置く
2. `CLAUDE.md` は薄くして `@AGENTS.md` を参照する
3. global では `.agents/AGENTS.md` を共通ソースにする
4. `~/.codex/AGENTS.md` と `~/.claude/CLAUDE.md` はその共通ファイルを指す

## install 方針

`install.sh` は AI CLI 用の managed file / directory を個別に symlink する。

重要:

- `~/.codex` や `~/.claude` を丸ごと置き換えない
- managed file だけ差し込む
- unmanaged な sibling file はそのまま残す
- `skills` はディレクトリごと symlink せず、child entry を個別 link する
  - これにより local-only skill を同じディレクトリに共存させられる
