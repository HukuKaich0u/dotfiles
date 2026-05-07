# Nix Root Relocation 設計

**Goal:** 現在 `.config/nix` に置いている Nix / Home Manager / nix-darwin の source of truth を repo root の `nix/` へ移し、実運用コマンドとテストが新パスで動く状態にする。

## スコープ

含むもの:
- `.config/nix` を `nix/` へ移動する
- shell regression test の `.config/nix/...` 参照を `nix/...` へ更新する
- 実用的な flake コマンド例を `./nix#...` に更新する
- 必要なら旧 `~/.config/nix` symlink を除去できる cleanup を `install.sh` に追加する
- `home-manager build --flake ./nix#KokiAoyagi` が通る状態まで確認する

含まないもの:
- `docs/superpowers/*` の historical spec / plan を全面追従させること
- `home-manager` / `nix-darwin` module の機能変更
- `~/.config` 配下の既存アプリ設定の再構成
- `darwin-rebuild` や大規模な macOS 設定変更

## 前提

- 現在の flake entry point は `.config/nix/flake.nix`
- 実行コマンドは `home-manager build --flake .config/nix#KokiAoyagi` や `home-manager switch --flake .config/nix#KokiAoyagi`
- Nix ツリー内部は `flake.nix` から `./common` `./home-manager` `./nix-darwin` を相対 import している
- `install.sh` は `.config` 配下だけを `~/.config` に symlink する
- 現在このマシンには `~/.config/nix` は存在しないが、他環境では残っている可能性がある

## 選択肢

### Option 1: `nix/` へ移し、実運用に必要な参照だけ更新する

`git mv .config/nix nix` を行い、テスト、現行コマンド例、legacy cleanup だけを追従させる。historical docs は更新しない。

Pros:
- 実害のある参照ズレだけを止められる
- 差分を必要最小限にできる
- 過去 docs の書き換えに時間を使わない

Cons:
- historical docs には古い `.config/nix` 表記が残る

### Option 2: `nix/` へ移し、docs も全面更新する

Pros:
- repo 全体で表記が統一される

Cons:
- 変更量の大半が docs になり、レビューしづらい
- 過去の手順書まで修正対象になり、今回の移行目的から外れる

### Option 3: `.config/nix` のままにして、repo root への facade だけ追加する

たとえば root に `nix` symlink や wrapper を置き、内部構造は維持する。

Pros:
- 既存参照をほぼ壊さない

Cons:
- source of truth が曖昧になる
- 「Nix ツリーを root に持ってきたい」という目的を満たさない

## 推奨案

Option 1 を採用する。

今回の目的は Nix ツリーの所有位置を変えることであり、docs の履歴修正ではない。したがって、実コード・テスト・実運用コマンドだけを追従させるのが最も実務的で安全である。

## 構成設計

### ディレクトリ移動

- `.config/nix` を `nix` へ移動する
- `flake.nix` `flake.lock` `common/` `home-manager/` `nix-darwin/` の相対関係はそのまま保つ

### `flake.nix`

`flake.nix` 自体の中身は原則変更しない。

理由:
- 既存の import は `./common` `./home-manager` `./nix-darwin` を基準にしている
- `flake.nix` ごと `nix/` に移せば内部相対パスはそのまま成立する

### shell regression tests

現在 `.config/nix/...` を直参照している path-based test をすべて `nix/...` へ更新する。

対象:
- `tests/bacon_home_manager_migration_test.sh`
- `tests/direnv_zsh_check_skip_test.sh`
- `tests/ghconfig_paths_test.sh`
- `tests/gitconfig_paths_test.sh`
- `tests/home_manager_only_flake_test.sh`
- `tests/mise_home_manager_bootstrap_test.sh`
- `tests/nix_darwin_reset_test.sh`
- `tests/tmux_nix_migration_test.sh`
- `tests/wezterm_home_manager_migration_test.sh`
- `tests/yazi_home_manager_migration_test.sh`
- `tests/zsh_nix_migration_test.sh`

### 実用コマンド

今後使うコマンドは path flake として `./nix#...` を使う。

置換方針:
- `home-manager build --flake .config/nix#KokiAoyagi`
  -> `home-manager build --flake ./nix#KokiAoyagi`
- `home-manager switch --flake .config/nix#KokiAoyagi`
  -> `home-manager switch --flake ./nix#KokiAoyagi`
- `nix eval .config/nix#...`
  -> `nix eval ./nix#...`

### `install.sh`

`install.sh` の `.config` linking 本体は変更しない。

理由:
- `nix/` は repo root に出るため、以後 `install.sh` が `~/.config/nix` を作ることはない
- `.config` 管理の責務と衝突しない

ただし legacy cleanup は追加候補とする。

責務:
- 過去環境で `~/.config/nix -> <repo>/.config/nix` が残っている場合に除去する
- 現在の `cleanup_legacy_ai_links` と同じく、repo 配下を向く symlink に限定して消す

## データフロー

移行後の実行フローは次のとおり。

1. `home-manager build --flake ./nix#KokiAoyagi` が `nix/flake.nix` を読む
2. `flake.nix` から `./common` `./home-manager` `./nix-darwin` を相対 import する
3. Home Manager / nix-darwin の評価結果は従来どおり生成される
4. `install.sh` は `nix/` に触らず、`.config` 配下の別設定だけを link する

## エラーハンドリング / 衝突対策

### stale `~/.config/nix` symlink

旧配置を link していた環境では `~/.config/nix` が残っている可能性がある。

今回の対策:
- `install.sh` に legacy cleanup を足すか
- 最低でも移行手順に `rm ~/.config/nix` を含める

cleanup を script に入れる場合の条件:
- symlink であること
- 現在の repo 配下を指していること

### flake path の指定ミス

`nix#...` ではなく `./nix#...` を使う必要がある。

この違いを放置すると:
- local path flake として解決されず失敗する
- 過去 docs のコピペがそのままでは使えない

そのため、実用コマンドは明示的に `./nix#...` へ統一する。

## テスト方針

### path regression

上記 11 テストを更新し、`nix/...` 前提でも通ることを確認する。

### flake evaluation

- `home-manager build --flake ./nix#KokiAoyagi`
- 必要に応じて `nix eval ./nix#homeConfigurations.KokiAoyagi.config.home.username --raw`

### install script safety

legacy cleanup を入れる場合は、repo 配下を向く `~/.config/nix` symlink だけを消すことを text test で固定する。

## 実装順

1. path regression test を先に更新して failing state を作る
2. `.config/nix` を `nix/` へ移動する
3. 必要な command references を更新する
4. `install.sh` に legacy cleanup を追加する
5. `home-manager build --flake ./nix#KokiAoyagi` で評価を確認する

## リスク

- path ベースの test を取りこぼすと見落としが残る
- stale `~/.config/nix` symlink が他マシンでだけ問題化する可能性がある
- historical docs に古い表記が残るため、将来それをコピペすると混乱する可能性がある

## 成功条件

- Nix の source of truth が repo root の `nix/` になる
- shell regression test が `nix/...` 前提で通る
- 実用的な flake コマンドが `./nix#...` 前提で使える
- `install.sh` 実行後も古い `~/.config/nix` symlink が残らない
