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

## Script 一覧

### `setup-linux.sh`

Linux 初回セットアップの入口。

実行順:

1. `install-linux-packages.sh core`
2. `--with-docker` 指定時は `install-linux-packages.sh linux-extra`
3. `rustup` を公式 installer で user install
4. `link-dotfiles.sh`

この script 自体は orchestrator で、個別処理の詳細は下の 2 本に委譲する。

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
- `rustup` を導入する
- repo 管理下の dotfiles link を張る

この script がやらないこと:

- `home-manager switch`
- Docker daemon の post-install 調整
- `rustup` の toolchain/channel カスタマイズ
- `gcloud init`

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

Linux 初回セットアップ:

```sh
./scripts/setup-linux.sh
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```

Docker も必要なら:

```sh
./scripts/setup-linux.sh --with-docker
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```
