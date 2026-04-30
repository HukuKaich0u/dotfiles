# starship Docker Context 設計

**Goal:** `starship` の Docker 表示を常時表示ではなく、Docker を使う repo とコンテナ内作業でだけ自然に出るようにする。

## 方針

- 対象は [`.config/starship.toml`](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/.config/starship.toml:1) の Docker 表示だけ
- 既存の built-in `docker_context` の見た目はできるだけ維持する
- 表示条件は `docker context` の有無ではなく、作業場所の性質で決める
- `aws` `gcp` など他クラウド表示は今回の対象外

## 背景

現状の `docker_context` は `Dockerfile` や `docker-compose.yml` がカレントディレクトリ直下付近で検知できる時だけ出る設定になっている。

このため、次のケースで表示が不足する。

- repo の深い階層に Docker 関連ファイルがある
- `.devcontainer` など Docker 利用の痕跡はあるが既存の検知条件に入っていない
- コンテナ内で作業しているのに Docker 文脈が見えない

## 選択肢

### Option 1: built-in `docker_context` の検知条件だけ増やす

- 設定差分が最小
- `detect_files` `detect_folders` だけで済む
- repo 配下の深い場所にある Docker 痕跡やコンテナ内検知は扱いづらい

### Option 2: built-in `docker_context` を常時表示にする

- 実装は最も簡単
- Docker を使わない repo でも常に出てノイズが増える

### Option 3: `custom.docker_context` に置き換える

- 表示条件を repo 全体と実行環境に対して柔軟に書ける
- 見た目は現状維持しやすい
- shell 判定ロジックを少し持つ必要がある

## 採用

Option 3。

「Docker を使う repo だけ表示したい」「コンテナ内でも表示したい」という要件は built-in の静的検知より custom 判定の方が素直に満たせるため。

## 設計

### 表示条件

次のどちらかを満たす時だけ Docker モジュールを表示する。

- Git repo root 配下のどこかに Docker 関連ファイルまたはフォルダがある
- 現在の shell がコンテナ内で動作している

Docker 関連の検知候補は次を想定する。

- `Dockerfile`
- `Containerfile`
- `docker-compose.yml`
- `docker-compose.yaml`
- `compose.yml`
- `compose.yaml`
- `.devcontainer/`
- `docker/`

repo 判定は `git rev-parse --show-toplevel` を使い、repo 外では無理に探索しない。

### 表示内容

- 表示文字列は `docker context show` の結果を使う
- icon と色は既存 `docker_context` の青系スタイルを引き継ぐ
- 配置順は現状どおり `git_status` の後ろに置く

### 実装境界

- 既存 `[docker_context]` は format から外すか無効化する
- 新しい `[custom.docker_context]` を追加する
- 判定用 command は失敗時に何も出さず、prompt 全体を壊さない

## エラーハンドリング

- `docker` command が無い場合は何も表示しない
- `docker context show` が失敗した場合は何も表示しない
- Git repo でない場所では repo 探索をせず、コンテナ判定だけを見る

## テスト観点

- repo root に `Dockerfile` がある時に表示される
- subdirectory 配下にだけ `Dockerfile` などがある repo でも表示される
- Docker 痕跡が無い repo では表示されない
- コンテナ内では repo 条件に関係なく表示される
- `docker` 未インストール環境で prompt が壊れない
