# mise Guide Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `mise` 初心者向けに、普段使うコマンドとこの repo の運用方針をまとめた 1 ページのガイドを追加する。

**Architecture:** `docs/mise-guide.md` を単一の入口にして、前半を汎用コマンド解説、後半を repo 固有の `nix + Home Manager + mise` の補足に分ける。内容の正本は既存の [nix/home-manager/mise.nix](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/nix/home-manager/mise.nix) に合わせる。

**Tech Stack:** Markdown, Nix config reference, mise

---

## Chunk 1: 文書構成を定める

### Task 1: ガイドの章立てを固定する

**Files:**
- Create: `docs/mise-guide.md`
- Check: `nix/home-manager/mise.nix`

- [ ] **Step 1: 見出し構成を決める**

章立ては次を使う。

```md
# mise Guide
## まず何をすればいいか
## よく使うコマンド
## project ごとに version を固定したいとき
## この repo ではどうなっているか
```

- [ ] **Step 2: repo 固有情報の正本を確認する**

Run: `sed -n '1,200p' nix/home-manager/mise.nix`
Expected: `tools.node`, `tools.go`, `tools.java`, `enableZshIntegration` が確認できる

## Chunk 2: ガイド本文を書く

### Task 2: 汎用入門を書く

**Files:**
- Create: `docs/mise-guide.md`

- [ ] **Step 1: 普段の使い方を書く**

次を説明する。

- 通常は `node`, `go`, `java` などをそのまま実行する
- 確認には `mise current`, `mise ls`, `mise which`
- 一時実行には `mise exec`

- [ ] **Step 2: project 固定の流れを書く**

次を説明する。

- `mise use <tool>@<version>`
- `mise install`
- `mise.toml` が project 単位の定義ファイルになる

### Task 3: repo 固有補足を書く

**Files:**
- Create: `docs/mise-guide.md`
- Check: `nix/home-manager/mise.nix`

- [ ] **Step 1: この repo の責務分担を書く**

次を明記する。

- global runtime の SoT は `nix/home-manager/mise.nix`
- global は `node 24`, `go 1.26`, `java 25`
- Python は global `mise` ではなく `uv` 寄り
- Rust は `rustup` 寄り

- [ ] **Step 2: 参照リンクを入れる**

`docs/mise-guide.md` から `nix/home-manager/mise.nix` へリンクする。

## Chunk 3: 整合確認

### Task 4: 内容の整合を確認する

**Files:**
- Check: `docs/mise-guide.md`
- Check: `nix/home-manager/mise.nix`

- [ ] **Step 1: 文書を読み返す**

Run: `sed -n '1,240p' docs/mise-guide.md`
Expected: 汎用説明と repo 固有補足が 1 ページにまとまっている

- [ ] **Step 2: 設定との差分がないか確認する**

Run: `sed -n '1,200p' nix/home-manager/mise.nix`
Expected: ドキュメント記載の version と責務分担が一致する

## Unresolved questions

- なし
