# AI CLI Dotfiles 設計

**日付:** 2026-04-12

## 目的

この dotfiles リポジトリでは、Codex と Claude Code のうち「どのマシンでも再現したい個人設定」だけを管理する。  
一方で、ローカル状態、キャッシュ、認証情報、trust 記録、プロジェクト固有の指示は global な dotfiles 管理から外す。

## 現状

- このリポジトリは現在、[install.sh](/Users/KokiAoyagi/Documents/repos/dotfiles/install.sh:1) で `~/.config/*` と一部の home dotfiles を symlink 管理している。
- `codex` は `/opt/homebrew/bin/codex` に入っている。
- `claude` は `/Users/KokiAoyagi/.local/bin/claude` に入っている。
- 現在の global 設定として実際に使っている主なファイルは以下。
  - Codex: `~/.codex/config.toml`
  - Claude Code: `~/.claude/settings.json`, `~/.claude/CLAUDE.md`
  - Codex user skills: `~/.agents/skills/*`
- 逆に、以下は local state なので管理対象から外すべき。
  - Codex: `auth.json`, `history.jsonl`, `sessions/`, `log/`, `sqlite/`, `state_*.sqlite*`, `rules/default.rules`, plugin cache, project trust 記録
  - Claude Code: `~/.claude.json`, `history.jsonl`, `projects/`, `todos/`, `shell-snapshots/`, `debug/`, `statsig/`

## 要件

- Codex / Claude Code の個人設定を別マシンでも再現できること
- global な skills / hooks / instruction file を dotfiles で管理できること
- project 固有の rules / skills / hooks は各 project repo 側で管理できること
- secret、auth state、cache、machine 固有 path を commit しないこと
- 既存の `install.sh` ベースの symlink 運用に乗ること

## 非目的

- 履歴、telemetry、cache、SQLite DB、session archive の管理
- project ごとの trust 状態の共有
- 各ツールの標準ファイル名を無視して、無理に 1 つのファイル名へ統一すること

## 推奨設計

### 1. 管理責務を 2 層に分ける

設定は以下の 2 層に分けて扱う。

- global personal layer
  - どのマシンでも共通で効かせたい個人設定
- project layer
  - その repo だけで意味を持つ rules / skills / hooks

この分け方にすると、dotfiles 側は portable に保てて、各ツールの project-local な運用も壊さない。

### 2. global 設定ファイルは同じ感覚で扱う

Codex でも Claude Code でも、ユーザーが直接触る global 設定ファイルは本質的には同じ種類のものとして扱う。

揃えるルール:

- repo 上では tool ごとにトップレベル配下へ寄せる
  - `.codex/*`
  - `.claude/*`
  - `.agents/skills/*`
- 「設定ファイル」「instruction file」「hooks」「skills」を同じ並びで置く
- `install.sh` では、どのツールでも「managed file を個別 link する」方式で統一する
- local state を含むディレクトリ全体は link しない
- 各ツール固有のファイル名は維持する
  - Codex は `AGENTS.md`
  - Claude Code は `CLAUDE.md`

つまり、使うファイル名はツール標準に合わせるが、repo での見え方と運用パターンはできるだけ揃える。

### 3. この dotfiles repo で管理する global ファイル

以下の構成を追加する。

```text
dotfiles/
  .agents/
    AGENTS.md
    skills/
  .codex/
    AGENTS.md
    config.toml
    hooks.json
    hooks/
  .claude/
    CLAUDE.md
    settings.json
    skills/
```

各ファイル・ディレクトリの責務は以下。

- `dotfiles/.codex/config.toml`
  - model、reasoning、personality、安定した plugin 設定など、portable な設定だけを持つ
  - machine 固有の `[projects.*]` trust 記録は持たない
- `dotfiles/.agents/AGENTS.md`
  - global instruction の共通ソース
- `dotfiles/.codex/AGENTS.md`
  - `dotfiles/.agents/AGENTS.md` を指す symlink
- `dotfiles/.codex/hooks.json` と `dotfiles/.codex/hooks/*`
  - Codex の global hooks と、その hook script
- `dotfiles/.claude/settings.json`
  - Claude Code の global 設定
  - model default や hook 宣言などを含める
- `dotfiles/.claude/CLAUDE.md`
  - `dotfiles/.agents/AGENTS.md` を指す symlink
- `dotfiles/.claude/skills/*`
  - Claude Code 専用 skill が必要な場合だけ使う
- `dotfiles/.agents/skills/*`
  - Codex user skills
  - `~/.agents/skills/*` へ child entry 単位で link する
  - `~/.codex/skills` は system skill 領域なので global user skill の一次置き場には使わない
  - Claude Code にも共通 skill を使わせる場合は `~/.claude/skills/*` から参照させる
  - `superpowers` のような共通 skill も可能な限りここで repo-managed にする

### 4. project 側に置くもの

repo 固有の設定は global dotfiles に載せず、各 project に置く。

- Codex
  - `AGENTS.md`
  - `AGENTS.override.md`
  - `.agents/skills/*`
  - `.codex/hooks.json`
  - `.codex/hooks/*`
- Claude Code
  - `CLAUDE.md` または `.claude/CLAUDE.md`
  - `.claude/settings.json`
  - `.claude/rules/*`
  - `.claude/skills/*`

### 5. instruction file の共通化方針

project で Codex と Claude Code に同じ方針を読ませたい場合は、`AGENTS.md` を一次ソースにする。  
global でも同じ考え方を使い、`.agents/AGENTS.md` を共通ソースにする。

推奨パターン:

- project root に `AGENTS.md` を置き、repo の本体ルールを書く
- `CLAUDE.md` は薄くして `@AGENTS.md` を読む
- global では `.codex/AGENTS.md` と `.claude/CLAUDE.md` を `.agents/AGENTS.md` への symlink にする

これなら project ルールの重複を避けつつ、両ツールの標準的な探索方法にも乗れる。

### 6. hooks の方針

hook は「その hook がどのスコープのルールを強制したいか」で置き場所を決める。

- global hooks
  - 起動時の個人リマインド
  - どの repo でも共通で走らせたい処理
- project hooks
  - その repo 固有の build / test / policy check

hook を使いたいだけで `~/.codex` や `~/.claude` を丸ごと symlink するのは避ける。  
管理対象は hook 設定ファイルと hook script のみとする。

### 7. install 戦略

`install.sh` を、今の「`.config/*` を上位ディレクトリ単位で全部 link する」方式から、ネストした file / dir も明示的に link できる方式へ拡張する。

必要な挙動:

- parent directory がなければ作る
- 以下の managed path を個別に link する
  - `dotfiles/.codex/config.toml -> ~/.codex/config.toml`
  - `dotfiles/.codex/AGENTS.md -> ~/.codex/AGENTS.md`
  - `dotfiles/.codex/hooks.json -> ~/.codex/hooks.json`
  - `dotfiles/.codex/hooks -> ~/.codex/hooks`
  - `dotfiles/.claude/settings.json -> ~/.claude/settings.json`
  - `dotfiles/.claude/CLAUDE.md -> ~/.claude/CLAUDE.md`
- `dotfiles/.claude/skills -> ~/.claude/skills`
  - `dotfiles/.agents/skills/* -> ~/.agents/skills/*`
- 既存の unmanaged file と衝突したら `*.backup` に退避する
- unmanaged な sibling file は触らない

重要なのは、`~/.codex` や `~/.claude` をディレクトリごと置き換えないこと。  
それらの配下には高頻度で変わる state が混ざっているため、managed file だけを部分的に差し込む構成にする。

`skills` についてはさらに一段細かく扱い、directory 全体ではなく child entry ごとに link する。  
共通 skill の一次ソースは `~/.agents/skills/*` とし、Claude Code には `~/.claude/skills/*` からその同じ entry を参照させる。  
これにより、repo 管理 skill と local-only skill を同じ skill 配下で共存させながら、Codex と Claude Code の両方で同じ skill を使える。

## sanitize ルール

既存の local 設定を repo に取り込む前に、以下の整理を行う。

- Codex `config.toml`
  - 残すもの
    - `model`
    - `model_reasoning_effort`
    - `personality`
    - 安定した plugin 設定
  - 落とすもの
    - `[projects.*]`
    - 意図的でない一時的 UI state
- Claude Code `settings.json`
  - 意図して設定した preference と hook 設定だけ残す
- Claude `CLAUDE.md`
  - 再利用したい個人 instruction なら残す
- 取り込まないもの
  - `~/.claude.json`
  - `~/.codex/auth.json`
  - `history.jsonl`
  - session snapshot
  - SQLite DB
  - cache directory
  - debug log

## 移行計画

### Phase 1. managed path を repo に追加する

- `.codex`, `.claude`, `.agents` を repo 側に作る
- 対象ファイルだけ sanitize して取り込む

### Phase 2. installer を拡張する

- `install.sh` を refactor して、現在の `.config/*` loop に加えて nested symlink を扱えるようにする
- 既存の `.config` と home dotfile の流れは壊さない

### Phase 3. guardrail を追加する

- `.gitignore` を広げて、stateful な AI tool file を誤って add しないようにする
- 何を dotfiles に置き、何を project に置くかの短い運用メモを追加する

### Phase 4. 動作確認する

- `./install.sh` を実行する
- link が正しく張られることを確認する
- linked file を使った状態で Codex / Claude Code が起動することを確認する

## リスク

### リスク: Codex の config が再び machine 固有情報を含み始める

対策:

- `dotfiles/.codex/config.toml` は raw copy ではなく curated file として扱う

### リスク: global rule と project rule が重複する

対策:

- global file には個人 default だけを書く
- repo policy は project-local `AGENTS.md` または `CLAUDE.md` に寄せる

### リスク: global hook script が repo 前提の path を持ってしまう

対策:

- 全 repo 共通で成立する hook だけ dotfiles に置く
- repo 依存の hook はその repo 側へ移す

## 採用方針

partial-link model を採用する。

- dotfiles では、AI CLI の global 設定ファイルだけを小さく明示的に管理する
- user skills は global skill directory として管理する
- project 固有の instructions / skills / hooks は各 project repo に置く
- `~/.codex` と `~/.claude` は丸ごと管理しない

## 次のステップ

次に implementation plan を書いて、以下を順に実施する。

1. repo に新しい managed directory と sanitize 済み config を追加する
2. `install.sh` を nested link 対応にする
3. `.gitignore` と短い運用ドキュメントを追加する
4. local で link と起動確認を行う
