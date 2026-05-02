# zsh PATH Responsibility 設計

**Goal:** `zsh` の環境初期化を理解しやすくするため、PATH と非 PATH の環境調整を `zsh.nix` に一元化し、zsh 設定の入口を 1 ファイルにする。

## スコープ

この設計は `zsh` の PATH と環境初期化の責務整理だけを対象にする。

含むもの:
- `zsh.nix` への環境初期化の一元化
- `env.zsh` と `homebrew.zsh` の廃止
- PATH 変更処理の `zsh.nix` への一元化
- `~/go/bin` の PATH 追加削除

含まないもの:
- `conda` や `gcloud` の利用自体の見直し
- `mise` 本体の導入や設定
- alias、補完、prompt の整理
- `zsh` 以外の dotfiles 整理

## 背景

現状は次のように責務がにじんでいる。

- [`zsh.nix`](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/.config/nix/home-manager/zsh.nix:35) と [`env.zsh`](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/.config/nix/home-manager/zsh/env.zsh:1) に環境初期化が分散している
- `cargo`, `openjdk`, `pnpm`, `conda`, `gcloud`, `homebrew`, `nix` の PATH 追加経路が複数箇所に散っている
- `env.zsh` が PATH と非 PATH の環境変数調整を同時に持っている

この状態だと「PATH の順番はどこで決まるのか」「`nix > homebrew` の優先順をどこで担保するのか」「Homebrew を有効化する責務はどこか」が追いづらい。

## 選択肢

### Option 1: 環境初期化を `zsh.nix` に集約する

- PATH を変更する処理と非 PATH の環境変数初期化を `zsh.nix` に集約する
- 分割 shell file を減らし、zsh 設定の入口を `zsh.nix` だけにする
- 「zsh の環境設定は `zsh.nix` を見れば全部わかる」状態を作れる

### Option 2: `zsh.nix` にほぼすべて寄せる

- 入口は最も明快になる
- ただし `conda` や `gcloud` の shell snippet まで Nix 文字列に埋まりやすく、編集体験は悪化しやすい

### Option 3: 現状維持でコメントだけ足す

- 変更量は少ない
- ただし責務の曖昧さは残る

## 採用

Option 1。

今回は「zsh の環境設定を 1 箇所で理解できること」が主目的である。そのため、PATH を変更する実処理だけでなく、残っている非 PATH の環境変数初期化も `zsh.nix` に寄せるのが最も認知負荷が低い。`conda` や `gcloud` などの外部 script は残してよいが、それを呼ぶ場所も `zsh.nix` に固定する。

## 構成設計

### `zsh.nix`

責務:
- `zsh` 設定の唯一の入口
- 環境初期化の唯一の入口
- `profileExtra` と `initContent` の読み込み順管理
- PATH の骨格、ツール別 PATH 初期化、非 PATH の環境変数初期化の定義

このファイルでは「どのレイヤの PATH が先に来るか」「どのツールが PATH を変更するか」「どの環境変数が追加されるか」がまとめて読める状態を目指す。特に、基礎レイヤでは `nix > homebrew` を明示する。

役割分担:
- `profileExtra`
  - login shell の初期化
  - PATH と環境変数の初期化をまとめて置く
- `initContent`
  - interactive shell の初期化
  - `bindkey` や `local.zsh` のような対話専用の調整だけを置く

想定する対象:
- `brew shellenv`
- `nix-daemon.sh`
- `~/.npm-global/bin`
- `~/.local/bin`
- `~/.cargo/env`
- `PNPM_HOME` に伴う PATH 追加
- `conda init`
- `google-cloud-sdk/path.zsh.inc`
- `~/.local/bin/env`
- `local.zsh`
- `ZSH_STATE_DIR`
- `HISTFILE`
- `JAVA_HOME`
- `PNPM_HOME`
- `CPLUS_INCLUDE_PATH`
- `google-cloud-sdk/completion.zsh.inc`
- 必要なら今後の `mise` PATH

`~/go/bin` は `mise` 移行方針に合わせて削除する。

## 起動フロー

1. `zsh.nix` の `profileExtra` が login shell 用の環境初期化を組み立てる
2. その中で `brew shellenv` を読み、Homebrew 系 PATH を入れる
3. 続けて `nix-daemon.sh` を読み、Nix 系 PATH が Homebrew より優先されるようにする
4. `profileExtra` が管理する基礎 PATH を追加する
5. `profileExtra` が `cargo`, `pnpm`, `conda`, `gcloud`, `~/.local/bin/env` の PATH 追加または PATH 変更の呼び出しを行う
6. `profileExtra` が `ZSH_STATE_DIR`, `HISTFILE`, `JAVA_HOME`, `PNPM_HOME`, `CPLUS_INCLUDE_PATH`, `gcloud` completion を初期化する
7. `initContent` が interactive shell 専用の `local.zsh` と `bindkey` を読み、最後の操作性調整だけを行う

## PATH 優先順

この整理では、PATH の基礎優先順を次の考え方で扱う。

1. Nix 系
2. Homebrew 系
3. ユーザー管理の追加 PATH
4. `profileExtra` 内のツール別 PATH 追加
5. `profileExtra` 内の非 PATH 環境変数初期化
6. `initContent` 経由の `local.zsh` による最終 override

少なくとも基礎レイヤでは `nix > homebrew` を維持し、環境初期化の責務は `zsh.nix` から外へ漏らさない。

## 具体的な整理内容

- `homebrew.zsh` を廃止し、`brew shellenv` を `zsh.nix` に移す
- `env.zsh` を廃止し、残っている非 PATH の環境変数初期化を `zsh.nix` に移す
- `~/go/bin` の PATH 追加を削除する
- `cargo`, `pnpm`, `conda`, `gcloud` の PATH 変更を `zsh.nix` に移す
- `~/.local/bin/env` と `local.zsh` の呼び出し元を `zsh.nix` に移す

## エラーハンドリング

- `zsh.nix` 内の Homebrew 初期化は `brew` 実体が見つかった時だけ有効化する
- `zsh.nix` 内の外部ツール PATH 初期化は存在確認つきのまま維持する
- `zsh.nix` 内の非 PATH 環境変数初期化も存在確認つきのまま維持する
- `local.zsh` は `zsh.nix` から存在時のみ読み込む

## テスト方針

1. 新しい shell で `echo $PATH` を見て `nix > homebrew` を含む順序が大きく崩れていないことを確認する
2. `command -v brew` `command -v nix` `command -v pnpm` を確認する
3. `command -v cargo` `command -v conda` `command -v gcloud` を確認する
4. `echo $JAVA_HOME` と `echo $PNPM_HOME` を確認する
5. `which -a` で代表的なコマンド解決順を確認する
6. `env.zsh` と `homebrew.zsh` が不要になったことを確認する

## 成功条件

- zsh の環境設定を見る場所が `zsh.nix` に一本化される
- 基礎 PATH の優先順が `nix > homebrew` で一貫する
- `env.zsh` が不要になる
- `homebrew.zsh` が不要になる
- `~/go/bin` 依存が消える
