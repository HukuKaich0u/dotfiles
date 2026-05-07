# mise Guide 設計

**Goal:** `mise` を初めて使う人が、普段どのコマンドを使えばよいかを短時間で理解でき、この repo の `nix + Home Manager + mise` 構成でどこを見ればよいかもわかるガイドを追加する。

## スコープ

含むもの:
- `mise` の基本的な役割の説明
- 普段よく使う `mise` コマンドの使い分け
- global runtime と project runtime の違い
- この repo 固有の `mise` 管理方針の補足

含まないもの:
- `mise` 自体のインストール手順
- 各 project の `mise.toml` 新規作成
- `nix` 設定の変更

## 方針

ドキュメントは `docs/mise-guide.md` の 1 枚構成にする。前半を汎用入門、後半をこの repo の補足に分ける。

読み順は「まず何を打つか」を優先する。

1. 普段は何もしなくてよい
2. version や解決結果を確認する
3. その場だけ特定 runtime でコマンドを実行する
4. project に version を固定する

## 採用する内容

- `mise current`
- `mise ls`
- `mise which`
- `mise exec`
- `mise use`
- `mise install`

これに加えて、`node --version` のように通常の実行ファイルをそのまま使う場面も明記する。

## この repo の補足

- source of truth は [nix/home-manager/mise.nix](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/nix/home-manager/mise.nix)
- global runtime は `node = 24` `go = 1.26` `java = 25`
- `programs.mise.enableZshIntegration = true` により shell 統合は有効
- Python は global `mise` の責務ではなく `uv` 寄り
- Rust は `rustup` 寄り

## 成功条件

- `mise` 未経験者が「何を打てば使えるか」を 1 ページで把握できる
- この repo で global runtime をどこで管理しているか分かる
- 一般論と repo 固有ルールの境界が明確
