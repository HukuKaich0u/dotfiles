# Scripts

このディレクトリには、dotfiles repo のセットアップを役割ごとに分けた script を置く。

## 方針

- `setup-*` は入口 script
- `install-*` は package や外部依存の導入
- `link-*` は repo 管理ファイルの symlink 配布

1 本に全部詰め込まず、権限と責務で分ける。

- OS package install は `sudo` が必要
- `rustup` は user-level installer
- dotfiles link は repo 配布処理

## Linux 最短手順

Linux の新規 bootstrap を最短で通すなら、まずこれだけ実行する。

Docker 不要:

```sh
./scripts/setup-linux.sh
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```

Docker も必要:

```sh
./scripts/setup-linux.sh --with-docker
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```

`setup-linux.sh` は orchestrator だけを担当する。apt repository 追加、package install、`rustup` install、dotfiles link の実装詳細は個別 script 側に置く。

## macOS 最短手順

macOS の新規 bootstrap を最短で通すなら、まずこれを実行する。

```sh
./scripts/setup-mac.sh
```

`setup-mac.sh` は orchestrator だけを担当する。Homebrew の導入確認、`darwin-rebuild switch --flake ./nix#KokiAoyagi`、dotfiles link の実装詳細は個別 script 側に置く。

手動 step:

```sh
sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake ./nix#KokiAoyagi
```

初回は `darwin-rebuild` がまだ無いことがある。その場合は上の command で一度 `nix-darwin` を適用してから、以後は `./scripts/setup-mac.sh` を再実行する。

`gcloud` を使うなら追加でこれを実行する。

```sh
gcloud init
```

## Script 一覧

### `setup-linux.sh`

Linux 初回セットアップの入口。

実行順:

1. `install-linux-packages.sh core`
2. `--with-docker` 指定時は `install-linux-packages.sh linux-extra`
3. `rustup` を公式 installer で user install
4. `link-dotfiles.sh`

この script 自体は orchestrator で、個別処理の詳細は下の 3 本に委譲する。

用途:

- 新しい Linux マシンをこの repo 向けに bootstrap したい時
- 何を最初に実行すればよいか迷いたくない時

例:

```sh
./scripts/setup-linux.sh
./scripts/setup-linux.sh --with-docker
```

この script がやること:

- Linux 用の base package を入れる
- 必要なら Docker package を入れる
- `install-rustup.sh` を呼ぶ
- repo 管理下の dotfiles link を張る

この script がやらないこと:

- `home-manager switch`
- Docker daemon の post-install 調整
- `rustup` install の実装詳細
- `rustup` の toolchain/channel カスタマイズ
- `gcloud init`

### `setup-mac.sh`

macOS 初回セットアップの入口。

実行順:

1. `install-homebrew.sh`
2. `apply-nix-darwin.sh`
3. `link-dotfiles.sh`

この script 自体は orchestrator で、個別処理の詳細は下の 3 本に委譲する。

用途:

- 新しい macOS マシンをこの repo 向けに bootstrap したい時
- 何を最初に実行すればよいか迷いたくない時

例:

```sh
./scripts/setup-mac.sh
```

この script がやること:

- Homebrew が無ければ install する
- `darwin-rebuild switch --flake ./nix#KokiAoyagi` を実行する
- repo 管理下の dotfiles link を張る

この script がやらないこと:

- `darwin-rebuild` 初回導入の完全自動化
- GUI app 側の認証や初期設定
- `gcloud auth login` や `gcloud init`

## `install-homebrew.sh`

macOS の Homebrew installer。

用途:

- Homebrew 導入だけを個別に再実行したい時
- mac bootstrap 前提を先に満たしたい時

例:

```sh
./scripts/install-homebrew.sh
```

この script がやること:

- macOS 判定
- `brew` が既にあれば clean に skip
- 未導入時のみ Homebrew 公式 installer を実行

この script がやらないこと:

- Homebrew formula / cask の適用
- `darwin-rebuild` 実行
- dotfiles の symlink 配布

## `apply-nix-darwin.sh`

macOS の `nix-darwin` apply script。

用途:

- `darwin-rebuild` だけ単体で再実行したい時
- Homebrew や dotfiles link を触らず Nix 側だけ反映したい時

例:

```sh
./scripts/apply-nix-darwin.sh
```

この script がやること:

- macOS 判定
- `nix` と `darwin-rebuild` の前提確認
- repo root で `darwin-rebuild switch --flake ./nix#KokiAoyagi` を実行

この script がやらないこと:

- Nix installer 自体の導入
- `darwin-rebuild` 初回導入の完全自動化
- dotfiles の symlink 配布

## `install-linux-packages.sh`

Linux の OS package installer。

対応:

- Debian / Ubuntu 系のみ

profile:

- `core`
  - Linux bootstrap に最低限必要な package
  - `ca-certificates`
  - `curl`
  - `zsh`
  - `unzip`
  - `build-essential`
  - `locales`
- `linux-extra`
  - Docker 用 package
  - Docker 公式 apt repository を登録してから install
  - `docker-ce`
  - `docker-ce-cli`
  - `containerd.io`
  - `docker-buildx-plugin`
  - `docker-compose-plugin`

用途:

- OS package だけを個別に入れ直したい時
- Docker 周りだけ後から足したい時

例:

```sh
./scripts/install-linux-packages.sh core
./scripts/install-linux-packages.sh linux-extra
```

この script がやること:

- distro 判定
- `apt-get update`
- profile に応じた package install
- Docker 公式 repo 設定

この script がやらないこと:

- `rustup` install
- dotfiles の symlink 配布
- Home Manager 実行

## `install-rustup.sh`

`rustup` の shared installer。

用途:

- Linux bootstrap から user-level の Rust 導入だけを切り出したい時
- `rustup` install を単体で再実行したい時

例:

```sh
./scripts/install-rustup.sh
```

この script がやること:

- 既存の `rustup` install を検知し、すでに入っていれば skip
- 未導入時のみ公式 installer を non-interactive で実行

この script がやらないこと:

- `apt` package install
- dotfiles の symlink 配布
- `rustup` の toolchain/channel カスタマイズ

## `link-dotfiles.sh`

repo 管理の dotfiles / config を home directory 配下へ link する script。

もともとの `install.sh` の責務をこの script に移した。

用途:

- symlink 配布だけやりたい時
- OS package install や `rustup` を触らずに dotfiles だけ反映したい時

例:

```sh
./scripts/link-dotfiles.sh
```

この script がやること:

- `~/.config` 配下の symlink 配布
- AI 関連ファイルの明示 link
- legacy link cleanup
- terminfo compile

この script がやらないこと:

- `apt` package install
- `rustup` install
- Home Manager 管理領域の配布

Home Manager 管理に移したものは link 対象外:

- `nvim`
- `tmux`
- `zsh`
- `wezterm`
- `yazi`
- `bacon`
- `starship.toml`

## 推奨手順

Linux は上の「Linux 最短手順」、macOS は「macOS 最短手順」がそのまま推奨手順。
