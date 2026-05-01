# zsh PATH Responsibility 設計

**Goal:** `zsh` の PATH 管理を理解しやすくするため、`zsh.nix` を入口にし、`env.zsh` を動的な微調整へ限定して責務を明確にする。

## スコープ

この設計は `zsh` の PATH と環境初期化の責務整理だけを対象にする。

含むもの:
- `zsh.nix` `env.zsh` `homebrew.zsh` の責務再定義
- PATH の大枠をどこで決めるかの整理
- `homebrew.zsh` の読み込み位置の一本化
- `~/go/bin` の PATH 追加削除

含まないもの:
- `conda` や `gcloud` の利用自体の見直し
- `mise` 本体の導入や設定
- alias、補完、prompt の整理
- `zsh` 以外の dotfiles 整理

## 背景

現状は次のように責務がにじんでいる。

- [`zsh.nix`](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/.config/nix/home-manager/zsh.nix:40) が `homebrew.zsh` と `nix-daemon.sh` を読む
- [`env.zsh`](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/.config/nix/home-manager/zsh/env.zsh:1) でも `homebrew.zsh` を再度読む
- [`env.zsh`](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/.config/nix/home-manager/zsh/env.zsh:19) が PATH の骨格、環境変数、外部ツール初期化、ローカル override をまとめて持っている

この状態だと「PATH の順番はどこで決まるのか」「`nix > homebrew` の優先順をどこで担保するのか」「Homebrew を有効化する責務はどこか」が追いづらい。

## 選択肢

### Option 1: `zsh.nix` を入口、`env.zsh` を動的調整に限定する

- PATH の骨格と読み込み順を `zsh.nix` に寄せる
- `env.zsh` は環境変数と外部ツール初期化だけに寄せる
- 理解しやすさと既存 script の維持を両立しやすい

### Option 2: `zsh.nix` にほぼすべて寄せる

- 入口は最も明快になる
- ただし `conda` や `gcloud` の shell snippet まで Nix 文字列に埋まりやすく、編集体験は悪化しやすい

### Option 3: 現状維持でコメントだけ足す

- 変更量は少ない
- ただし責務の曖昧さは残る

## 採用

Option 1。

今回は「理解しやすい入口を作ること」が主目的であり、同時に `conda` や `gcloud` のような動的 script まで無理に Nix 化する必要はない。そのため、`zsh.nix` に PATH の骨格と読み込み順を集約しつつ、`env.zsh` は runtime 依存の微調整に限定するのが最も素直である。

## 構成設計

### `zsh.nix`

責務:
- `zsh` 設定の唯一の入口
- `profileExtra` と `initContent` の読み込み順管理
- PATH の骨格定義
- `homebrew.zsh` と `nix-daemon.sh` の読み込み

このファイルでは「どのレイヤの PATH が先に来るか」が読める状態を目指す。特に、基礎レイヤでは `nix > homebrew` を明示する。

想定する対象:
- `homebrew.zsh`
- `nix-daemon.sh`
- `~/.npm-global/bin`
- `~/.local/bin`
- `/opt/homebrew/opt/postgresql@17/bin`
- 必要なら今後の `mise` PATH

`~/go/bin` は `mise` 移行方針に合わせて削除する。

### `env.zsh`

責務:
- 実行時にだけ必要な微調整
- 条件付き環境変数
- 外部ツール初期化
- ローカル override

残す対象:
- `ZSH_STATE_DIR`
- `HISTFILE`
- `JAVA_HOME`
- `PNPM_HOME`
- `~/.local/bin/env`
- `conda init`
- `google-cloud-sdk`
- `local.zsh`

原則として、PATH の大枠や基礎レイヤの再定義は持たない。

### `homebrew.zsh`

責務:
- `brew shellenv` だけ

このファイルは Homebrew を shell から使える状態にするだけの薄い wrapper とし、PATH 設計そのものは持たない。

## 起動フロー

1. `zsh.nix` が login shell 用の基礎初期化を組み立てる
2. その中で `homebrew.zsh` を 1 回だけ読む
3. 続けて `nix-daemon.sh` を読み、Nix 系 PATH が Homebrew より優先されるようにする
4. `zsh.nix` が管理する基礎 PATH を追加する
5. interactive shell で `env.zsh` を読み、環境変数や外部ツール初期化を行う
6. 必要なら `local.zsh` で最終 override を行う

## PATH 優先順

この整理では、PATH の基礎優先順を次の考え方で扱う。

1. Nix 系
2. Homebrew 系
3. ユーザー管理の追加 PATH
4. `env.zsh` や `local.zsh` による動的な最終微調整

少なくとも基礎レイヤでは `nix > homebrew` を維持し、`env.zsh` はその前提を壊さない範囲でのみ追加調整を行う。

## 具体的な整理内容

- [`env.zsh`](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/.config/nix/home-manager/zsh/env.zsh:1) 先頭の `source "$ZDOTDIR/homebrew.zsh"` を削除する
- [`env.zsh`](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/.config/nix/home-manager/zsh/env.zsh:20) の `~/go/bin` 追加を削除する
- PATH の `prepend` / `append` 群を `zsh.nix` に移す
- `env.zsh` には PATH 骨格ではなく動的調整だけ残す

## エラーハンドリング

- `homebrew.zsh` は `brew` 実体が見つかった時だけ有効化する
- `env.zsh` の外部ツール初期化は存在確認つきのまま維持する
- `local.zsh` は存在時のみ読み込む

## テスト方針

1. 新しい shell で `echo $PATH` を見て `nix > homebrew` を含む順序が大きく崩れていないことを確認する
2. `command -v brew` `command -v nix` `command -v pnpm` を確認する
3. `echo $JAVA_HOME` と `echo $PNPM_HOME` を確認する
4. `conda` と `gcloud` が従来どおり利用可能か確認する
5. `which -a` で代表的なコマンド解決順を確認する

## 成功条件

- PATH の骨格を見る場所が `zsh.nix` に寄る
- 基礎 PATH の優先順が `nix > homebrew` で一貫する
- `homebrew.zsh` の読み込み責務が 1 箇所にまとまる
- `env.zsh` が動的調整用ファイルとして理解しやすくなる
- `~/go/bin` 依存が消える
