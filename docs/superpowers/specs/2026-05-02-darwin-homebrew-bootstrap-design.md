# darwin Homebrew Bootstrap 設計

**Goal:** `nix-darwin` 配下に Homebrew 専用 module を追加し、まずは `homebrew.enable = true;` だけを darwin 側から管理できる土台を作る。

## スコープ

含むもの:
- `.config/nix/nix-darwin/homebrew.nix` の新設
- `.config/nix/nix-darwin/configuration.nix` からの import 追加
- `homebrew.enable = true;` のみを使った最小の Homebrew 土台
- テキスト回帰テストと `nix eval` による確認

含まないもの:
- `homebrew.brews`, `homebrew.casks`, `homebrew.taps` の追加
- `darwin-rebuild build` や `darwin-rebuild switch`
- `home-manager` 側設定の変更

## 選択肢

### Option 1: `configuration.nix` に直接 `homebrew.enable = true;` を書く

Pros:
- 最短で動く

Cons:
- `homebrew` 関連が増えたときに `configuration.nix` が太りやすい
- 専用責務が分かれない

### Option 2: `homebrew.nix` を新設して import する

Pros:
- 将来 `taps`, `brews`, `casks`, `onActivation` を追加しやすい
- `darwin` 本体と Homebrew 設定の責務を分けられる
- 今回の段階的な進め方に最も合う

Cons:
- 初回はファイルが1つ増える

### Option 3: `flake.nix` 側へ直接書く

Pros:
- なし

Cons:
- `flake.nix` は入口であり、中身を書く場所ではない
- 責務が崩れる

## 推奨案

Option 2 を採用する。

今回はまだ Homebrew の管理対象一覧を決める段階ではない。まずは `nix-darwin` の中に Homebrew 専用 module を置き、darwin 側の本体からそれを読む構造だけを作る。その上で、将来 `brews`, `casks`, `taps` を安全に足せるようにする。

## 構成設計

### `.config/nix/nix-darwin/configuration.nix`

追加するもの:
- `./homebrew.nix` の import

役割:
- `darwin` 側の本体として、Homebrew module も読み込む

### `.config/nix/nix-darwin/homebrew.nix`

新規作成する。

最初に書くもの:
- `homebrew.enable = true;`

今後ここに書く候補:
- `homebrew.taps`
- `homebrew.brews`
- `homebrew.casks`
- `homebrew.onActivation.*`

### `.config/nix/home-manager/*`

今回は変更しない。

## データフロー

1. `flake.nix` の `darwinConfigurations."KokiAoyagi"` が `configuration.nix` を読む
2. `configuration.nix` が `home_manager.nix` と `homebrew.nix` を import する
3. `homebrew.nix` が `homebrew.enable = true;` を定義する
4. `darwinConfigurations."KokiAoyagi"` から Homebrew の有効化状態を参照できる

## 確認方針

今回は次の2段階で確認する。

1. テキスト回帰テスト
2. `nix eval`

確認すること:
- `configuration.nix` が `./homebrew.nix` を import している
- `homebrew.nix` に `homebrew.enable = true;` がある
- `darwinConfigurations."KokiAoyagi"` から `homebrew.enable` が `true` と見える

今回は慎重に進めるため、`darwin-rebuild build` や `switch` はまだ行わない。

## 実装単位

1. `homebrew.nix` を新設する
2. `configuration.nix` に import を追加する
3. テキスト回帰テストで配線を固定する
4. `nix eval` で有効化状態を確認する
5. 次段で Homebrew 管理対象の追加へ進む

## リスク

- `homebrew.enable` だけでは、まだ管理対象一覧は何もない
- `nix eval` が通っても、`darwin-rebuild build` までは未確認の段階に留まる

## 成功条件

- `configuration.nix` が `homebrew.nix` を import する
- `homebrew.nix` が `homebrew.enable = true;` を定義する
- `darwinConfigurations."KokiAoyagi"` から Homebrew の有効化が確認できる
- `home-manager` 側には変更が入らない
