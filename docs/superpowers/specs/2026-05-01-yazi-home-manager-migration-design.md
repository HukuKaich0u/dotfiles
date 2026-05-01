# yazi Home Manager Migration 設計

**Goal:** `yazi` の本体導入と既存 `yazi.toml` 設定を `home-manager` 管理へ移し、現在の挙動を変えずに `install.sh` ベースの symlink 管理から切り離す。

## スコープ

この設計は、既存の `yazi` 設定を `home-manager` 配下へ安全に移行するためのもの。

含むもの:
- `programs.yazi` による `yazi` 本体管理
- 既存 `.config/yazi/yazi.toml` の `programs.yazi.settings` への移植
- `.config/nix/home-manager/home.nix` への `./yazi.nix` 追加
- `install.sh` の symlink 管理対象から `yazi` を外すための整理

含まないもの:
- shell integration の追加
- `y` / `yy` wrapper の導入
- plugin / flavor / `init.lua` の導入
- `yazi` の keymap / theme / vfs 設定の新設
- 現在の `yazi` 挙動の見直し

## 選択肢

### Option 1: `programs.yazi.settings` に既存設定を写す

`programs.yazi.enable = true` で本体を管理し、現在の `yazi.toml` を Nix attrset へ変換して `programs.yazi.settings` に持つ。

Pros:
- `yazi` 専用 module の標準形に乗る
- 本体導入と設定配布の責務が 1 か所にまとまる
- 将来 shell integration や plugin を足す時も同じ `yazi.nix` を拡張すればよい
- 今回の設定量なら変換コストが低い

Cons:
- TOML を Nix attrset に変換する小さな手間がある

### Option 2: `programs.yazi.enable` + `home.file` で `yazi.toml` をそのまま配る

`programs.yazi.enable = true` で本体だけ管理し、設定ファイルは `home.file` もしくは `xdg.configFile` でそのまま配布する。

Pros:
- 既存ファイルをほぼそのまま使える
- 初回変換量が最小

Cons:
- `yazi` 設定の責務が module option と file 配布に分かれる
- 将来拡張時に構造がぶれやすい
- 今回の設定規模だと簡略化の利得が小さい

## 推奨案

Option 1 を採用する。

今回は「まず Home Manager に移すこと」が目的であり、機能追加や整理は後回しにする。その条件では、`programs.yazi` の標準的な入口に現在の設定をそのまま表現するのが最も素直で安全である。設定量は小さく、`mgr` と `preview` の単純な値しか持っていないため、Nix attrset への変換による回帰リスクも低い。

## 構成設計

### `home.nix`

- `.config/nix/home-manager/home.nix` に `./yazi.nix` を追加する
- 既存の import 構成に合わせて `git/gh/starship/tmux/zsh` と同列に置く

### `yazi.nix`

新規に `.config/nix/home-manager/yazi.nix` を追加し、`programs.yazi` の設定を集約する。

想定する責務:
- `programs.yazi.enable = true`
- `programs.yazi.settings.mgr` に既存 `yazi.toml` の `mgr` セクションを移す
- `programs.yazi.settings.preview` に既存 `yazi.toml` の `preview` セクションを移す
- shell integration 関連 option は今回は設定しない

### 既存 `yazi.toml` の扱い

- runtime の source of truth は `yazi.nix` 側へ移す
- 既存 `.config/yazi/yazi.toml` は repo から削除する
- `install.sh` は `.config/yazi` をこれ以上 `~/.config/yazi` へ symlink しない状態にする

## 設定マッピング

現在の設定は次の程度なので、ほぼ 1 対 1 で移せる。

- `mgr.ratio = [1 4 3]`
- `mgr.sort_by = "natural"`
- `mgr.sort_sensitive = false`
- `mgr.sort_reverse = false`
- `mgr.sort_dir_first = true`
- `mgr.linemode = "size"`
- `mgr.show_hidden = true`
- `mgr.show_symlink = true`
- `mgr.scrolloff = 5`
- `preview.wrap = "yes"`
- `preview.tab_size = 2`

コメントは生成 TOML には残らないが、値の意味自体は維持される。

## データフロー

1. `home-manager` が `programs.yazi.settings` から `~/.config/yazi/yazi.toml` を生成する
2. `yazi` 実行時はその生成ファイルを読む
3. `install.sh` は `yazi` 配下に関与しない

これにより、`yazi` の runtime 管理主体は symlink ではなく Home Manager になる。

## エラーハンドリング / 衝突対策

### 既存 symlink との衝突

現在は `install.sh` が `.config` 配下を包括的に `~/.config` へ link しているため、既存 `~/.config/yazi` が repo への symlink になっている環境では Home Manager の生成先と衝突する可能性がある。

初回適用では以下を確認対象にする。

- `~/.config/yazi` が既存 symlink かどうか
- Home Manager 適用前に unlink または退避が必要かどうか

今回の実装では、少なくとも repo 側の `install.sh` から `yazi` 配布責務を外し、今後の再リンクを防ぐ。

### 挙動差分の抑制

今回は shell integration、plugin、theme、keymap を触らない。

これにより、移行後に起きうる差分はほぼ以下に限られる。

- 生成された TOML のコメントがなくなる
- 既存 symlink から Home Manager 生成ファイルへ管理主体が変わる

## 実装単位

1. `.config/nix/home-manager/yazi.nix` を追加する
2. `.config/nix/home-manager/home.nix` に `./yazi.nix` を追加する
3. 既存 `.config/yazi/yazi.toml` を `programs.yazi.settings` へ移す
4. repo から `.config/yazi/yazi.toml` を削除する
5. `install.sh` の `SKIP_CONFIG_DIRS` に `yazi` を加え、symlink 配布対象から外す
6. Home Manager build で生成設定を確認する

## テスト方針

1. `home-manager build --flake .config/nix#KokiAoyagi` が通る
2. build 生成物に `~/.config/yazi/yazi.toml` 相当のファイルが含まれる
3. 生成 TOML に既存設定値が反映されている
4. `yazi` 起動時に設定エラーが出ない

## リスク

- 既存 `~/.config/yazi` symlink が残っていると初回 switch 時に衝突する可能性がある
- TOML コメントは失われるため、説明は Nix 側に残すか受け入れる必要がある
- 将来 shell integration を入れる時に wrapper 名の選択を別途決める必要がある

## 成功条件

- `yazi` 本体が Home Manager 管理になる
- `~/.config/yazi/yazi.toml` の source of truth が `yazi.nix` に移る
- `install.sh` が `yazi` を再リンクしない
- 既存の `yazi` 挙動が実用上変わらない
