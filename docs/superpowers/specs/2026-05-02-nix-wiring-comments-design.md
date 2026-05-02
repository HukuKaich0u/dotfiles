# Nix Wiring Comments 設計

**Goal:** 直近で整理した `flake.nix` と `nix-darwin` 周辺に、Nix に不慣れでも役割と記述場所がわかる説明コメントを追加する。

## スコープ

含むもの:
- `.config/nix/flake.nix` への入口説明コメント追加
- `.config/nix/nix-darwin/configuration.nix` への `darwin` 本体説明コメント追加
- `.config/nix/nix-darwin/home_manager.nix` への接続役説明コメント追加

含まないもの:
- Nix の挙動変更
- `.config/nix/home-manager/*` の設定変更
- `homebrew` や `system.defaults` の実装追加

## 選択肢

### Option 1: 最小限のコメントだけ足す

各ファイルの先頭や主要式に短いコメントだけを足す。

Pros:
- 設定ファイルが簡潔なまま

Cons:
- Nix に不慣れなときには説明がやや不足する

### Option 2: 役割と記述場所がわかるコメントを丁寧に足す

`なぜ` に加えて、`ここに何を書く場所なのか` も明示する。

Pros:
- 将来読み返したときに迷いにくい
- `flake` / `darwin` / `home-manager` の責務分担が見える
- 今回の要望に最も合う

Cons:
- コメント量は少し増える

### Option 3: 各行に近い粒度で細かくコメントする

Pros:
- 学習用としては詳しい

Cons:
- Nix 式そのものが読みにくくなりやすい
- 保守時のノイズが増える

## 推奨案

Option 2 を採用する。

コメントは「なぜその配線なのか」だけではなく、「このファイルには何を書く場所なのか」を説明する。これにより、`flake.nix` は入口、`configuration.nix` は `darwin` 本体、`home_manager.nix` は接続、`home-manager/*.nix` はユーザー設定本体、という地図がコード上に残る。

## 構成設計

### `.config/nix/flake.nix`

追加する説明:
- このファイルは flake の入口定義を書く場所
- `homeConfigurations."KokiAoyagi"` は `home-manager` 単体入口で、比較用・退避用として残している
- `darwinConfigurations."KokiAoyagi"` は `darwin` 経由の本命入口
- `home-manager.darwinModules.home-manager` は、`nix-darwin` 側から `home-manager.*` option を解釈するために必要

### `.config/nix/nix-darwin/configuration.nix`

追加する説明:
- このファイルは `darwin` 側の本体設定を書く場所
- 現時点では最小 bridge として使っている
- 将来的に `homebrew`, `system.defaults`, `security`, `users` などの macOS / `darwin` 寄り設定を書く場所
- 現在残している各 option が `darwin` の基本情報として必要な理由

### `.config/nix/nix-darwin/home_manager.nix`

追加する説明:
- このファイルは `home-manager` の中身を書く場所ではない
- `darwin` から既存の `home-manager` 設定へ接続するためのファイル
- 実際の shell, git, tmux などは `../home-manager/home.nix` とその import 先に書く

## 実装単位

1. `flake.nix` に入口と module 配線の説明コメントを追加する
2. `configuration.nix` に責務と今後書く設定種別の説明コメントを追加する
3. `home_manager.nix` に接続役としての説明コメントを追加する
4. コメント追加後も既存テストで挙動が変わっていないことを確認する

## リスク

- コメントが細かすぎると将来の保守ノイズになる
- 現状と将来像を同時に書くため、実装前の話を断定的に書きすぎると誤解を生む

## 成功条件

- 各ファイルの役割がコメントだけで追える
- 「ここに何を書くか」と「なぜその配線なのか」の両方が伝わる
- 設定の意味は増えるが、Nix の挙動自体は変わらない
