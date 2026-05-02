# mise Home Manager Bootstrap 設計

**Goal:** `mise` 本体の導入責務を Homebrew から `home-manager` へ移し、今後の `mise` 設定追加に備えて program 単位の module 構成へ載せる。

## スコープ

この設計は `mise` 本体を `home-manager` 管理へ切り替える最小変更だけを対象にする。

含むもの:
- `.config/nix/home-manager/mise.nix` の新設
- `.config/nix/home-manager/home.nix` への `./mise.nix` 追加
- `programs.mise.enable = true` による `mise` 本体管理

含まないもの:
- `mise activate` など shell hook の導入
- `mise.toml` や `config.toml` の管理
- language / runtime 定義の Nix への移植
- 既存 `zsh.nix` の PATH や shell 初期化の見直し

## 背景

現状、`mise` は Homebrew から削除済みで、ローカル環境には `mise` 実体が存在しない。

一方、この repo では `gh.nix`、`tmux.nix`、`yazi.nix`、`zsh.nix` のように program ごとに `home-manager` module を分ける構成がすでに採用されている。そのため `mise` も同じ粒度で module を追加するのが自然である。

## 選択肢

### Option 1: `home.nix` に直接 `programs.mise.enable = true` を書く

Pros:
- 変更ファイル数が最小
- 初回導入だけなら十分に単純

Cons:
- 将来 `mise` 設定を足す時に `home.nix` が肥大化しやすい
- 既存の program 単位 module 構成と揃わない

### Option 2: `mise.nix` を新設して `home.nix` から import する

Pros:
- 既存 repo の構成に揃う
- 将来 shell hook や config 管理を足しやすい
- `mise` の責務を 1 ファイルへ閉じ込められる

Cons:
- 初回導入としては 1 ファイル増える

## 採用

Option 2。

今回は変更量自体は小さいが、この repo は Home Manager の責務を program 単位 module に分ける方向で整理されている。`mise` だけ例外的に `home.nix` へ直書きすると、後で設定を増やした時に構成がぶれる。最初から `mise.nix` を切っておく方が拡張しやすい。

## 構成設計

### `home.nix`

- `.config/nix/home-manager/home.nix` の `imports` に `./mise.nix` を追加する
- 配置は既存 program module 群と同列にする

### `mise.nix`

新規に `.config/nix/home-manager/mise.nix` を追加し、責務を次に限定する。

- `programs.mise.enable = true`

今回は追加 option を持たせない。設定を増やすのは `mise` 本体が Nix 管理へ移ったあとでよい。

## データフロー

1. `home-manager` が `programs.mise.enable = true` を評価する
2. `mise` バイナリは Nix profile 経由で提供される
3. shell からは Nix 側の `mise` 実体が解決される

## エラーハンドリング / 衝突対策

- Homebrew 版 `mise` はすでに削除済みなので、PATH 上の二重管理は起きにくい
- ただし shell hook は今回導入しないため、`mise activate` 前提の補完や shim 挙動は次段階で別途扱う
- 既存 `zsh.nix` の未コミット変更には触れず、`mise` 本体導入の責務だけを分離する

## テスト方針

1. `home-manager build --flake .config/nix#KokiAoyagi` が通る
2. `nix eval .config/nix#homeConfigurations.KokiAoyagi.config.programs.mise.enable --raw` が `true` を返す
3. Home Manager 適用後に `which mise` が Nix profile 配下を指す

## 成功条件

- `mise` 本体が Home Manager 管理になる
- `home.nix` ではなく `mise.nix` が `mise` の責務を持つ
- 今後 hook や config を `mise.nix` に追加できる土台ができる
