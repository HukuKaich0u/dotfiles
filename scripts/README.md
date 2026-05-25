# Scripts

このディレクトリには、dotfiles repo の bootstrap を役割ごとに分けた script を置く。

end-to-end の環境構築手順は repo root の `README.md` を参照。
この README は script catalog と各 script の責務整理に集中する。

## 方針

- `setup-*` は OS ごとの入口 script
- `install-*` は package や外部依存の導入
- `link-*` は repo 管理ファイルの symlink 配布
- script は複数回実行しても壊れにくい前提で保つ

権限も責務も混ぜない。

- OS package install は `sudo` が必要
- `rustup` は user-level installer
- dotfiles link は repo 配布処理

## Linux 最短手順

Docker 不要:

```sh
./scripts/setup-linux.sh
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```

Ubuntu Desktop で Ghostty も必要:

```sh
./scripts/setup-linux.sh --with-ghostty
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```

Docker も必要:

```sh
./scripts/setup-linux.sh --with-docker
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```

Docker と Ghostty の両方が必要:

```sh
./scripts/setup-linux.sh --with-docker --with-ghostty
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```

`setup-linux.sh` は orchestrator だけを担当する。apt repository 追加、package install、Ghostty install、`rustup` install、dotfiles link の実装詳細は個別 script 側に置く。

## macOS 最短手順

```sh
./scripts/setup-mac.sh
```

`setup-mac.sh` は orchestrator だけを担当する。Homebrew の導入確認、`sudo darwin-rebuild switch --flake ./nix#KokiAoyagi`、dotfiles link の実装詳細は個別 script 側に置く。`ghostty` 自体の package ownership は `nix/modules/darwin/homebrew.nix` にある。

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

- 役割: Linux bootstrap の入口
- 実行順: `install-linux-packages.sh core` → 必要なら `install-linux-packages.sh linux-extra` → 必要なら `install-ghostty-linux.sh` → `install-rustup.sh` → `link-dotfiles.sh`
- やらないこと: `home-manager switch`、Docker daemon の post-install 調整、`gcloud init`
- 例: `./scripts/setup-linux.sh`, `./scripts/setup-linux.sh --with-docker`, `./scripts/setup-linux.sh --with-ghostty`

### `setup-mac.sh`

- 役割: macOS bootstrap の入口
- 実行順: `install-homebrew.sh` → `apply-nix-darwin.sh` → `link-dotfiles.sh`
- やらないこと: `darwin-rebuild` 初回導入の完全自動化、GUI app 側の認証や初期設定、`gcloud init`
- 例: `./scripts/setup-mac.sh`

### `install-homebrew.sh`

- 役割: macOS の Homebrew installer
- やること: macOS 判定、既存 `brew` の skip、未導入時のみ Homebrew 公式 installer 実行
- やらないこと: Homebrew formula / cask の適用、`darwin-rebuild` 実行、dotfiles 配布
- 例: `./scripts/install-homebrew.sh`

### `apply-nix-darwin.sh`

- 役割: macOS の `nix-darwin` apply
- やること: macOS 判定、`nix` と `darwin-rebuild` の前提確認、repo root で `sudo darwin-rebuild switch --flake ./nix#KokiAoyagi` 実行
- やらないこと: Nix installer 自体の導入、`darwin-rebuild` 初回導入の完全自動化、dotfiles 配布
- 例: `./scripts/apply-nix-darwin.sh`

### `install-linux-packages.sh`

- 役割: Debian / Ubuntu 向け OS package installer
- profile:
  - `core`: `ca-certificates`, `curl`, `zsh`, `unzip`, `build-essential`, `locales`, `google-cloud-cli`
  - `linux-extra`: Docker 公式 apt repository を登録してから `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`
- やらないこと: `rustup` install、dotfiles 配布、Home Manager 実行
- 例: `./scripts/install-linux-packages.sh core`, `./scripts/install-linux-packages.sh linux-extra`

### `install-rustup.sh`

- 役割: `rustup` の shared installer
- やること: 既存 install の検知、未導入時のみ公式 installer を non-interactive で実行
- やらないこと: `apt` package install、dotfiles 配布、toolchain/channel カスタマイズ
- 例: `./scripts/install-rustup.sh`

### `install-ghostty-linux.sh`

- 役割: Ubuntu 向け `ghostty` installer
- やること: Ubuntu 判定、既存 `ghostty` の skip、Ghostty docs が案内している Ubuntu installer 実行
- やらないこと: `apt` profile 管理、dotfiles 配布、`ghostty` 設定ファイル管理
- 例: `./scripts/install-ghostty-linux.sh`

### `link-dotfiles.sh`

- 役割: repo 管理の dotfiles / config を home directory 配下へ link
- やること: `~/.config` 配下の symlink 配布、AI 関連ファイルの明示 link、legacy link cleanup、terminfo compile
- やらないこと: `apt` package install、`rustup` install、Home Manager 管理領域の配布
- link 対象外: `nvim`, `tmux`, `zsh`, `wezterm`, `ghostty`, `yazi`, `bacon`, `starship.toml`
- 例: `./scripts/link-dotfiles.sh`

## 推奨手順

Linux は上の「Linux 最短手順」、macOS は「macOS 最短手順」がそのまま推奨手順。
