# darwin Home Manager Wiring 設計

**Goal:** 既存の `home-manager` 単体入口を残したまま、`nix-darwin` 経由でも同じ `home-manager` 設定を呼べる `darwinConfigurations."KokiAoyagi"` を追加する。

## スコープ

含むもの:
- `.config/nix/flake.nix` への `darwinConfigurations."KokiAoyagi"` 追加
- 既存の `nix-darwin/configuration.nix` と `nix-darwin/home_manager.nix` を使った配線
- `homeConfigurations."KokiAoyagi"` を残した段階的移行
- テキスト回帰テストと `nix eval` による確認

含まないもの:
- `.config/nix/home-manager/*` の変更
- `homebrew` 管理の追加
- `system.defaults` など macOS 設定の再導入
- `darwin-rebuild switch` による適用

## 選択肢

### Option 1: `homeConfigurations` を残したまま `darwinConfigurations` を追加する

既存の `home-manager` 単体入口を維持しつつ、追加で `darwin` 側の入口を生やす。

Pros:
- 比較用と退避用の入口を残せる
- どこで問題が起きたか切り分けやすい
- 今回の「慎重に進める」に最も合う

Cons:
- 移行期間中は入口が二重になる

### Option 2: ただちに `darwinConfigurations` 中心へ切り替える

`darwin` 側の入口を追加し、`homeConfigurations` はすぐ消す。

Pros:
- 最終形に早く近づく

Cons:
- 失敗時の退避路がなくなる
- 切り分けが難しくなる

### Option 3: 入口追加と同時に `nix-darwin` 設定も戻す

`darwinConfigurations` を追加しつつ、`configuration.nix` に共通設定や macOS 設定も戻す。

Pros:
- 一度に前へ進める

Cons:
- 変更点が増えて確認単位が粗くなる
- 入口の配線問題と設定本体の問題が混ざる

## 推奨案

Option 1 を採用する。

今回はまず `darwin` 側の入口だけを追加し、`home-manager` 設定本体は一切変えない。`homeConfigurations."KokiAoyagi"` を残すことで、`darwin` 配線の追加が本当に安全にできているかを比較しながら確認できる。

## 構成設計

### `.config/nix/flake.nix`

このファイルを今回の主変更点とする。

残すもの:
- `homeConfigurations."KokiAoyagi"`
- `home-manager.lib.homeManagerConfiguration`

追加するもの:
- `darwinConfigurations."KokiAoyagi"`
- `nix-darwin.lib.darwinSystem`
- `system = "aarch64-darwin"`
- `modules = [ ./nix-darwin/configuration.nix ]`

役割:
- `homeConfigurations."KokiAoyagi"` は既存どおり `home-manager` 単体入口
- `darwinConfigurations."KokiAoyagi"` は新しい `darwin` 入口

### `.config/nix/nix-darwin/configuration.nix`

今回は変更しない。

役割:
- `darwin` 側の最小構成を保持する
- `./home_manager.nix` を import する

### `.config/nix/nix-darwin/home_manager.nix`

今回は変更しない。

役割:
- `home-manager.users."KokiAoyagi" = ../home-manager/home.nix;` を通して、既存の `home-manager` 設定へ橋渡しする

### `.config/nix/home-manager/*`

今回は変更しない。

## データフロー

呼び出しの流れは次のとおり。

1. `flake.nix` の `darwinConfigurations."KokiAoyagi"` を `darwin-rebuild` が参照する
2. `nix-darwin/configuration.nix` が読み込まれる
3. その中で `nix-darwin/home_manager.nix` が読み込まれる
4. 最終的に `home-manager/home.nix` が読み込まれ、既存のユーザー設定が適用対象になる

## 確認方針

今回は段階的に確認する。

1. テキスト回帰テストを追加する
2. `nix eval` で `darwinConfigurations."KokiAoyagi"` が見えることを確認する
3. `homeConfigurations."KokiAoyagi"` が引き続き残っていることも確認する

今回は慎重に進めるため、初回段階では `darwin-rebuild build` や `darwin-rebuild switch` までは含めない。

## 実装単位

1. `flake.nix` に `darwinConfigurations."KokiAoyagi"` を追加する
2. `homeConfigurations."KokiAoyagi"` が残っていることをテストで固定する
3. `darwinConfigurations."KokiAoyagi"` が追加されていることをテストで固定する
4. `nix eval` で新旧の入口が見えることを確認する
5. レビュー後に次段の `darwin` 設定拡張へ進む

## リスク

- `darwinConfigurations` の入口名変更時に、`darwin-rebuild --flake` の指定名も追従させる必要がある
- `flake` 配線だけ直しても、次段で `darwin` 本体設定を増やす際に別の問題が出る可能性がある
- `nix eval` が通っても、まだ `darwin-rebuild build` までは確認していない段階に留まる

## 成功条件

- `flake.nix` が `homeConfigurations."KokiAoyagi"` と `darwinConfigurations."KokiAoyagi"` を両方公開する
- `darwinConfigurations."KokiAoyagi"` が `.config/nix/nix-darwin/configuration.nix` を起点に既存の `home-manager` 設定へ到達する
- `home-manager` 配下の設定内容に変更が入らない
- 初回確認はテキストテストと `nix eval` までに限定される
