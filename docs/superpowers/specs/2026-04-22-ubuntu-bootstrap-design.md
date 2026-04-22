# Ubuntu Bootstrap 設計

**Goal:** UTM 上の Ubuntu VM でこの dotfiles リポジトリを clone したあと、1 コマンドで CLI 中心の開発環境を整え、そのまま既存の dotfiles リンク設定まで反映できるようにする。

## スコープ

この設計は、CLI 中心の Ubuntu 初期構築用スクリプトを新規追加するためのもの。

含むもの:
- Ubuntu かどうかの判定と、非対応環境での早期終了
- `apt` によるベースパッケージの導入
- Node.js / npm 導入後の Codex CLI 導入
- 既存の `install.sh` の実行
- 必要に応じた login shell の `zsh` への切り替え
- 実行後に必要な手順の表示

含まないもの:
- Nix / Home Manager
- Docker やコンテナ関連ツール
- Rust toolchain の導入
- Language Server の導入
- GUI アプリケーション

## 選択肢

### Option 1: 最小の `apt` bootstrap + 既存 installer

`scripts/bootstrap-ubuntu.sh` を追加し、必要パッケージの導入、Codex CLI の導入、`./install.sh` の実行までを行う。

Pros:
- 変更範囲が最も小さい
- 現在のリポジトリ構成に自然に乗る
- fresh な Ubuntu VM で切り分けしやすい

Cons:
- パッケージのバージョンは Ubuntu repo に依存する
- 一部の開発ツール導入はあえて手動のまま残る

### Option 2: 開発ツールまで含めた重い bootstrap

Rust、Docker、Language Server、追加の editor 依存まで bootstrap に含める。

Pros:
- すぐに使える完成形に近づく

Cons:
- 失敗点が増える
- 保守コストが上がる
- ベース環境構築と言語別セットアップが混ざる

### Option 3: Nix ベース bootstrap

Nix を導入し、環境構築を宣言的に管理する。

Pros:
- 長期的な再現性は高い

Cons:
- 初期導入コストと保守コストが増える
- 現在の repo の install モデルと合わない
- 今回の目的に対しては重い

## 推奨案

Option 1 を採用する。

今の repo 構成に最も自然に合い、Ubuntu 初期構築を単純に保てる。Rust や Docker などの次段階をあとから足す余地も残せるため、最初の一歩として適切。

## スクリプト設計

`scripts/bootstrap-ubuntu.sh` を追加し、以下の段階で処理する。

1. 環境確認
   - OS が Ubuntu か確認する
   - `sudo` など必要コマンドの存在を確認する
   - 条件を満たさなければ、対処可能なメッセージを出して終了する

2. Ubuntu パッケージ導入
   - `sudo apt update` を実行する
   - 以下を install する
     - `git`
     - `curl`
     - `zsh`
     - `tmux`
     - `neovim`
     - `ripgrep`
     - `fd-find`
     - `fzf`
     - `unzip`
     - `build-essential`
     - `nodejs`
     - `npm`

3. Codex CLI 導入
   - `install_codex()` を実装する
   - すでに `codex` が `PATH` 上にあれば skip する
   - なければ `npm install -g @openai/codex` を実行する
   - その後 `command -v codex` で確認する
   - まだ見つからなければ、明確なエラーで停止する

4. dotfiles 反映
   - repo の `./install.sh` を実行する

5. shell 設定の仕上げ
   - 現在の login shell が `zsh` でなければ `chsh -s "$(command -v zsh)"` を試みる
   - 非対話では変更できない場合は、ユーザーに実行すべきコマンドを表示する

6. 実行後の案内
   - `codex login`
   - shell を再起動する、またはログアウト・再ログインする
   - `tmux` と `nvim` を起動して確認する

## エラーハンドリング

- `set -euo pipefail` を使う
- パッケージ導入失敗時は即終了する
- Codex 導入後に `codex` が `PATH` に見えなければ停止する
- `install.sh` が失敗したら停止する
- メッセージは短く具体的にし、原因を追いやすくする

## 既存 installer との関係

既存の `install.sh` は、repo 管理下の設定を home directory に link するための source of truth のまま維持する。新しい Ubuntu bootstrap script は、その設定が実用になるようにマシン側を整える外側のレイヤーとして扱う。

責務は次のように分離する。
- `bootstrap-ubuntu.sh`: マシン準備とツール導入
- `install.sh`: dotfiles link と terminfo 設定

## テスト方針

fresh な Ubuntu VM で手動確認する。

1. repo を clone する
2. `./scripts/bootstrap-ubuntu.sh` を実行する
3. 以下を確認する
   - `zsh --version`
   - `tmux -V`
   - `nvim --version`
   - `codex --help`
4. 新しい shell を開き、読み込まれた dotfiles が即座に壊れていないことを確認する

## リスク

- Ubuntu repo の `nodejs` / `npm` は upstream より古い可能性がある
- npm global bin の配置差で、`codex` が install 後すぐ `PATH` に見えない可能性がある
- 既存 shell config が、この first-pass bootstrap でまだ入れていないコマンドを前提にしている可能性がある

## 今後の拡張

後続で別 script や flag を追加する余地がある。

- Rust bootstrap
- Docker / container workflow 向け bootstrap
- Language Server / formatter など editor 依存の bootstrap
