# nix-darwin Reset 設計

**Goal:** `home-manager` は維持したまま、`nix-darwin` 側を `home-manager` 連携だけを担う最小構成へ戻す。

## スコープ

含むもの:
- `.config/nix/nix-darwin/configuration.nix` の最小化
- `nix-darwin` 側の macOS 設定、共通 Nix 設定 import の撤去
- レビュー用差分の作成

含まないもの:
- `.config/nix/home-manager/*` の変更
- `darwin-rebuild` や `home-manager switch` の実行
- `homebrew` 管理の追加

## 選択肢

### Option 1: `nix-darwin` を最小骨組みに戻す

`configuration.nix` を `home-manager` 連携に必要な値だけを持つ薄い入口へ戻す。

Pros:
- 今回の「更地にしてから積み直す」という目的に最も合う
- `darwin` と `home-manager` の責務境界が明確になる
- 次段で `darwin` 管理を再導入しやすい

Cons:
- 既存の macOS 設定は一時的にすべて `nix-darwin` 管理外になる

### Option 2: `system.defaults` だけ消し、土台は残す

見た目上の macOS 設定だけ外し、`nixpkgs` import などの足場は残す。

Pros:
- 変更量はやや少ない

Cons:
- 「更地化」としては中途半端
- 次段で何を再導入するかの境界が曖昧なまま残る

### Option 3: `nix-darwin` 自体を外して `home-manager` 単体へ戻す

Pros:
- 最も強い更地化

Cons:
- その後に `darwin` で `home-manager` を管理する流れと逆行する
- 今回の目的に合わない

## 推奨案

Option 1 を採用する。

`nix-darwin` は「`home-manager` をぶら下げるための最小エントリポイント」だけを担い、ユーザー環境管理は既存どおり `home-manager` 側に残す。これにより、今回の更地化と次段の再構築の両方をシンプルに進められる。

## 構成設計

### `.config/nix/nix-darwin/configuration.nix`

残すもの:
- `system.stateVersion`
- `system.configurationRevision`
- `system.primaryUser`
- `users.users.KokiAoyagi.home`
- `imports = [ ./home_manager.nix ]`

削除するもの:
- `../common/nixpkgs.nix` の import
- `nix.enable = false`
- `system.defaults` 一式
- `nixpkgs.hostPlatform`
- `security.pam.services.sudo_local.touchIdAuth`

### `.config/nix/nix-darwin/home_manager.nix`

このファイルは現状維持とする。

役割:
- `home-manager.useGlobalPkgs`
- `home-manager.useUserPackages`
- `home-manager.users."KokiAoyagi"` の接続

### `.config/nix/home-manager/*`

今回の作業では変更しない。`home-manager` は既存構成をそのまま維持する。

## 実装単位

1. `configuration.nix` の現状構成を確認する
2. 最小構成として残す項目だけを整理する
3. 不要な import と macOS 設定を削除する
4. レビュー用差分を確認する

## テスト方針

今回は適用しないため、実行系テストは行わない。

確認対象:
1. `configuration.nix` が最小構成だけを持っていること
2. `home_manager.nix` と `home-manager` 配下に差分がないこと
3. `darwin-rebuild` をまだ実行していないこと

## リスク

- `nix-darwin` 最小構成でも環境によっては追加の必須項目がある可能性がある
- 適用前レビューのみなので、実行時に初めて見つかる不足が残る可能性がある

## 成功条件

- `nix-darwin` 側の責務が `home-manager` 連携の最小骨組みに限定される
- `home-manager` 側には変更が入らない
- 差分はレビュー可能な状態で止まり、適用はユーザーレビュー後になる
