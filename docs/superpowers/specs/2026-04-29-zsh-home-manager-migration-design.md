# zsh Home Manager Migration 設計

**Goal:** `zsh` の管理主体を `install.sh` ベースの symlink 運用から `home-manager` に移し、設定実体を `~/.config/zsh` に寄せつつ、現在の shell 挙動をできるだけ変えずに移行する。

## スコープ

この設計は、既存の `zsh` 設定を `home-manager` 配下へ安全に移行するためのもの。

含むもの:
- `programs.zsh` による `zsh` 管理
- `programs.zsh.dotDir` を使った `~/.config/zsh` への配置
- 既存 `.zshenv` `.zprofile` `.zshrc` の入口を Home Manager 管理へ移行
- 既存 `env.zsh` `aliases.zsh` `completion.zsh` `plugins.zsh` `homebrew.zsh` の repo 内移設
- `brew shellenv`、`conda`、`gcloud`、`local.zsh` を初回移行では維持
- 現在の履歴配置 `~/.local/state/zsh/.zsh_history` の維持

含まないもの:
- Homebrew 依存の除去
- `conda init` や `google-cloud-sdk` 初期化の整理
- alias や plugin 設定の全面 Nix option 化
- `zsh` 以外の dotfiles の Nix 移行
- shell 挙動の大幅な見直し

## 選択肢

### Option 1: `programs.zsh` + `dotDir` + 既存 script 分割の維持

`programs.zsh` を有効化し、`programs.zsh.dotDir` で `~/.config/zsh` を設定する。`~/.zshenv` は Home Manager が生成する入口に任せ、設定本体は repo 内の分割ファイルを source する。

Pros:
- XDG 系の他設定と置き場所が揃う
- 現在の分割構成をほぼ維持できる
- 既存挙動を保ちやすい
- `install.sh` 依存を外しつつ責務を Home Manager に寄せられる

Cons:
- `~/.zshenv` の生成経路が 1 段増える
- `dotDir` を理解していないと最初は追いづらい

### Option 2: `programs.zsh` を使うが `dotDir` は使わない

Home Manager に `~/.zshenv` `~/.zprofile` `~/.zshrc` をホーム直下に生成させ、その中から repo 内の分割ファイルを source する。

Pros:
- Zsh の起動経路はより単純
- `dotDir` の理解が不要

Cons:
- `zsh` だけホーム直下に設定が残る
- `~/.config` に寄せる方針と揃わない

### Option 3: alias / plugin / env を広く Nix option 化する

`programs.zsh.shellAliases`、補完、plugin option などへ大きく分解し、shell script を最小化する。

Pros:
- 宣言的には最も一貫する
- 将来的な整理としては有効

Cons:
- 初回移行としては変更量が大きい
- 回帰リスクが高い
- いまの「1つずつ安全に移す」という目的と合わない

## 推奨案

Option 1 を採用する。

今回の優先順位は「`install.sh` から `home-manager` へ責務を移すこと」と「現在の shell 挙動を壊さないこと」の両立にある。そのためには、Zsh module 自体は `programs.zsh` に乗せつつ、既存の shell script 分割はそのまま活かすのが最も安全である。`dotDir` により `~/.config/zsh` へ設定を集約できるため、見た目と責務の一貫性も保てる。

## 構成設計

### `home.nix`

- `./zsh.nix` を import する
- 必要なら `xdg.enable = true` を有効化する

### `zsh.nix`

新規に `.config/nix/home-manager/zsh.nix` を追加し、`programs.zsh` の設定を集約する。

想定する責務:
- `programs.zsh.enable = true`
- `programs.zsh.dotDir = "${config.xdg.configHome}/zsh"` を明示
- `programs.zsh.enableCompletion = true`
- `programs.zsh.history.path` を `~/.local/state/zsh/.zsh_history` に合わせる
- `envExtra` `profileExtra` `initExtra` で repo 内の分割ファイルを source する
- 初回移行では plugin や prompt を無理に Nix option 化せず、既存 shell script を尊重する

### `zsh/` 配下の分割ファイル

新規に `.config/nix/home-manager/zsh/` を作り、既存 `.config/zsh/` から次を移す。

- `env.zsh`
- `aliases.zsh`
- `completion.zsh`
- `plugins.zsh`
- `homebrew.zsh`

必要なら `local.zsh` は追跡対象にせず、存在する場合のみ読む現在の挙動を維持する。

### 生成される runtime 構成

- Home Manager が `~/.zshenv` を生成し、`~/.config/zsh/.zshenv` を source する
- `~/.config/zsh/.zshenv` `~/.config/zsh/.zprofile` `~/.config/zsh/.zshrc` は Home Manager が生成する
- それぞれが repo 内の `zsh/*.zsh` を source する

## データフロー / 起動フロー

1. zsh 起動時に `~/.zshenv` を読む
2. Home Manager が生成した入口経由で `ZDOTDIR=~/.config/zsh` を使う
3. `~/.config/zsh/.zshenv` が読み込まれ、環境変数と PATH 初期化が実行される
4. login shell では `~/.config/zsh/.zprofile` が読み込まれ、`brew shellenv` と `hm-session-vars` が有効になる
5. interactive shell では `~/.config/zsh/.zshrc` が読み込まれ、alias、補完、plugin、prompt が有効になる

## エラーハンドリング / 衝突対策

### 既存 symlink との衝突

現在は `install.sh` が `~/.zshenv` `~/.zprofile` `~/.zshrc` と `~/.config/zsh` を配置しているため、初回の Home Manager 適用時に衝突する可能性が高い。

初回移行では以下を前提にする。

- 実装側で既存ファイル配置と Home Manager の生成先が重なることを確認する
- 適用前に退避または unlink が必要な対象を明示する
- いきなり Homebrew や `conda` の整理を同時に行わない

### ローカル依存の維持

次のようなローカル依存は初回では維持する。

- `brew shellenv`
- `~/.local/bin/env`
- `conda init`
- `google-cloud-sdk`
- `local.zsh`

これにより、移行後の問題切り分けを `zsh` の配置と Home Manager 生成に集中させる。

## 実装単位

1. `.config/nix/home-manager/zsh.nix` を追加する
2. `.config/nix/home-manager/home.nix` に `./zsh.nix` を追加する
3. 既存 `.config/zsh/` の管理対象ファイルを `.config/nix/home-manager/zsh/` へ移す
4. `zsh.nix` から分割ファイルを source する `.zshenv` `.zprofile` `.zshrc` を生成する
5. `history.path` と補完の保存先を現行の XDG 配置に合わせる
6. 初回適用時の衝突対象を確認し、安全に切り替える
7. `install.sh` から shell 関連の責務を外す準備をする

## テスト方針

移行後は手動確認を行う。

1. `home-manager` または `darwin-rebuild` の build / switch が通る
2. 新規 zsh で `echo $ZDOTDIR` が `~/.config/zsh` を指す
3. `echo $HISTFILE` が `~/.local/state/zsh/.zsh_history` を指す
4. alias、補完、starship、autosuggestion、syntax highlighting が従来どおり動く
5. `brew`, `conda`, `gcloud` が shell 起動後に使える
6. login shell と interactive shell の双方でエラーが出ない

## リスク

- `~/.zshenv` の既存 symlink と Home Manager 生成物が衝突する可能性がある
- `hm-session-vars.sh` の source 順序を誤ると PATH や環境変数が崩れる可能性がある
- `brew shellenv` と Nix profile の順序次第でコマンド解決順が変わる可能性がある
- `completion.zsh` の扱いを誤ると `compinit` の保存先や補完読み込み順が変わる可能性がある

## 成功条件

- `zsh` の入口と設定本体が Home Manager 管理へ移る
- 設定実体は `~/.config/zsh` に集約される
- 既存の shell 挙動が実用上維持される
- 初回移行で Homebrew や各種ローカル依存を壊さない
- `install.sh` から shell 管理の責務を外せる状態になる
