# Ghostty Bootstrap Design

## Goal

- Linux では Ubuntu Desktop のときだけ `ghostty` を opt-in で入れられるようにする
- Ubuntu Server では既定の bootstrap に `ghostty` を含めない
- macOS では既存どおり `nix-darwin` の Homebrew cask 管理を正とする
- README を更新し、OS ごとの `ghostty` の入れ方が一読で分かる状態にする

## Approved Direction

- Linux は `./scripts/setup-linux.sh --with-ghostty` を新設する
- `ghostty` の Linux 導入は専用 script `scripts/install-ghostty-linux.sh` に分離する
- macOS は bootstrap script を増やさず、`nix/modules/darwin/homebrew.nix` の `casks` で管理を続ける

Linux の `ghostty` は `docker` と同じく opt-in だが、導入方式は `apt` profile ではなく専用 script に切り出す。理由は、要件が「Ubuntu では公式の `curl` command を実行形式で管理したい」であり、既存の `install-linux-packages.sh` は apt repository / package install の責務に限定したいから。

## Script Responsibilities

### Linux

- `scripts/setup-linux.sh`
  - `--with-ghostty` option を受ける
  - 指定時のみ `install-ghostty-linux.sh` を呼ぶ
  - 既存の `--with-docker` と同様に orchestrator の責務だけを持つ
- `scripts/install-ghostty-linux.sh`
  - Ubuntu 判定
  - 必須 command の事前確認
  - 既存 install の skip 判定
  - `ghostty` 公式の `curl` ベース installer 実行

### macOS

- `scripts/setup-mac.sh`
  - 変更なし
- `scripts/install-homebrew.sh`
  - 変更なし
- `nix/modules/darwin/homebrew.nix`
  - `ghostty` を Homebrew cask として管理する source of truth

## Execution Flow

### Linux

server 向けの既定:

1. `./scripts/setup-linux.sh`
2. `home-manager switch --flake ./nix#kokiaoyagi`

desktop で `ghostty` も必要:

1. `./scripts/setup-linux.sh --with-ghostty`
2. `home-manager switch --flake ./nix#kokiaoyagi`

docker と `ghostty` の両方が必要:

1. `./scripts/setup-linux.sh --with-docker --with-ghostty`
2. `home-manager switch --flake ./nix#kokiaoyagi`

`setup-linux.sh` の内部順序は次とする。

1. `install-linux-packages.sh core`
2. `--with-docker` 時は `install-linux-packages.sh linux-extra`
3. `--with-ghostty` 時は `install-ghostty-linux.sh`
4. `install-rustup.sh`
5. `link-dotfiles.sh`

### macOS

1. `./scripts/setup-mac.sh`

`ghostty` は `setup-mac.sh` が呼ぶ `darwin-rebuild switch --flake ./nix#KokiAoyagi` の中で、`nix/modules/darwin/homebrew.nix` に定義された cask として適用される。

## Idempotency And Error Handling

- `install-ghostty-linux.sh` は Ubuntu 以外では失敗させる
- `curl` が無ければ明示的な error message で止める
- `ghostty` command が既に存在する場合は installer を再実行せず skip する
- `setup-linux.sh` は未知 option を今まで通り reject する
- 既存の `core` / `linux-extra` apt 処理には `ghostty` 用の責務を混ぜない

## README Changes

- `README.md`
  - Linux setup に `--with-ghostty` の例を追加する
  - macOS では `ghostty` が `nix-darwin` + Homebrew cask 管理で入ることを明記する
- `scripts/README.md`
  - Linux shortest path に server / desktop の分岐を追加する
  - `setup-linux.sh` の例に `--with-ghostty` を追加する
  - `install-ghostty-linux.sh` の責務を catalog に追加する
- `nix/README.md`
  - Linux shortest path に `--with-ghostty` の例を追加する
  - macOS の `ghostty` 管理元が `modules/darwin/homebrew.nix` であることを明記する

## Testing

最低限この範囲を shell test で確認する。

- `setup-linux.sh --with-ghostty` が `install-ghostty-linux.sh` を正しい順序で呼ぶ
- `setup-linux.sh --with-docker --with-ghostty` が両方を呼ぶ
- `install-ghostty-linux.sh` が `curl` 不在時に分かる error を出す
- `install-ghostty-linux.sh` が `ghostty` 既存時に skip する
- README 群に `ghostty` の新導線が記載される

## Out Of Scope

- Linux での `ghostty` 設定ファイル管理
- `ghostty` の desktop entry や theme 調整
- Linux 向け GUI app 全般の管理方式見直し
