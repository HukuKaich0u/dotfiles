# Cross-Platform Bootstrap Design

## Goal

- mac と Ubuntu の両方で、手順に従えば同じ user 環境へ寄せられる状態を作る
- 自動化できる部分は script へ寄せ、対話や認証が必要な部分は README に明記する
- script は責務ごとに分割し、総実行用 script から順に呼び出す構造にそろえる
- script は複数回実行されても壊れにくいことを前提にする

## Approved Direction

bootstrap は OS ごとに 1 本の入口 script を置き、その中で責務別 script を順に呼ぶ。

- Linux: `setup-linux.sh`
- macOS: `setup-mac.sh`

入口 script 自体は orchestrator として保ち、実処理を 1 file 1 responsibility に分ける。

## Script Responsibilities

### Shared

- `scripts/link-dotfiles.sh`
  - repo 管理ファイルの symlink 配布
  - Home Manager 管理対象は link しない
- `scripts/install-rustup.sh`
  - user-level の `rustup` install
  - 導入済みなら再 install しない

### Linux

- `scripts/setup-linux.sh`
  - Linux bootstrap 全体の入口
  - 下位 script を順に呼ぶだけに保つ
- `scripts/install-linux-packages.sh`
  - Ubuntu/Debian の `apt` package install
  - `google-cloud-cli` を含む OS package の導入

### macOS

- `scripts/setup-mac.sh`
  - mac bootstrap 全体の入口
  - 下位 script を順に呼ぶだけに保つ
- `scripts/install-homebrew.sh`
  - Homebrew 自体の install 確認と必要時 install
- `scripts/apply-nix-darwin.sh`
  - Nix / `darwin-rebuild` の前提確認
  - `darwin-rebuild switch --flake ./nix#KokiAoyagi` 実行

mac 側で Homebrew package の適用を独立 script に切り出すかは、`darwin-rebuild` の責務と重複しない最小構成で決める。少なくとも入口 script から見て「Homebrew install」と「nix-darwin apply」が分かれていることを優先する。

## Execution Flow

### Linux

1. `./scripts/setup-linux.sh`
2. 必要なら `./scripts/setup-linux.sh --with-docker`
3. `home-manager switch --flake ./nix#kokiaoyagi`
4. `gcloud` を使うなら `gcloud init`

`setup-linux.sh` の内部順序は次とする。

1. `install-linux-packages.sh core`
2. `--with-docker` 時は `install-linux-packages.sh linux-extra`
3. `install-rustup.sh`
4. `link-dotfiles.sh`

### macOS

1. `./scripts/setup-mac.sh`
2. 必要なら README に従って追加の手動確認

`setup-mac.sh` の内部順序は次とする。

1. `install-homebrew.sh`
2. `apply-nix-darwin.sh`
3. `link-dotfiles.sh`

## README Responsibilities

### `scripts/README.md`

- script catalog
- 各 script の責務
- 各 script がやること / やらないこと
- mac と Linux の推奨実行順
- 再実行してよい command であること

### `nix/README.md`

- Nix 側 source of truth
- bootstrap 後に user が行う Nix / Home Manager apply 手順
- `gcloud init` のような手動 step

README を見れば少なくとも次が分かる状態にする。

- mac では何を 1 番上から実行するか
- Ubuntu では何を 1 番上から実行するか
- その command が内部でどの script を呼ぶか
- どこからが手動 step か

## Idempotency Requirements

全 script は複数回実行前提で設計する。

必須条件:

- すでに導入済みの tool を前提に失敗しない
- install 済みなら skip できる
- symlink は同一 target なら再作成しない
- 別 target なら明示的に relink する
- shell config や repo file へ重複追記しない
- repo 登録処理は、同じ設定を何度流しても壊れない

具体的には次を守る。

- Homebrew install script は `brew` があれば再 install しない
- rustup install script は `~/.cargo/env` や `rustup` command を見て再 install しない
- Linux apt repo 追加は、同じ repo file と keyring を安全に上書きまたは再利用できる形にする
- `link-dotfiles.sh` は現状どおり既存 symlink を確認して再利用する

## Error Handling

- 非対応 OS では早期に停止し、対応環境を明示する
- 必須 command がない場合は install step か prerequisites を明示する
- 下位 script が失敗した時は入口 script も失敗扱いにする
- 対話が必要な step は script 内で半端に自動化せず、README に明示して止める

## Testing

少なくとも次を shell test で確認する。

- `setup-linux.sh` が責務別 script を呼ぶ
- `setup-mac.sh` が責務別 script を呼ぶ
- mac bootstrap 用 script が存在する
- `scripts/README.md` に mac / Ubuntu の再現手順がある
- 冪等性前提の guard が各 install script にある

## Out of Scope

- `gcloud init` の完全自動化
- 各種認証情報の自動投入
- Docker daemon post-install 調整の自動化
- mac / Linux の全 GUI app install 戦略の再設計
