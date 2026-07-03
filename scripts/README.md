# Scripts

このディレクトリには、dotfiles repo の bootstrap を役割ごとに分けた script を置く。

end-to-end の環境構築手順は repo root の `README.md` を参照。
この README は script catalog と各 script の責務整理に集中する。

## 方針

- `mac/` は macOS 専用の入口と installer
- `linux/` は Linux 専用の入口と installer
- `common/` は macOS / Linux 共通の user-level installer と dotfiles 配布
- `scripts/` 直下に wrapper は置かない
- script は複数回実行しても壊れにくい前提で保つ

権限も責務も混ぜない。

- OS package install は `sudo` が必要
- `rustup` は user-level installer
- dotfiles link は repo 配布処理

## Linux 最短手順

Docker 不要:

```sh
./scripts/linux/setup.sh
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```

Ubuntu Desktop で Ghostty も必要:

```sh
./scripts/linux/setup.sh --with-ghostty
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```

Docker も必要:

```sh
./scripts/linux/setup.sh --with-docker
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```

Docker と Ghostty の両方が必要:

```sh
./scripts/linux/setup.sh --with-docker --with-ghostty
home-manager switch --flake ./nix#kokiaoyagi
gcloud init
```

Claude Code も必要ならこれを実行する。

```sh
./scripts/common/install-claude-code.sh
```

`scripts/linux/setup.sh` は orchestrator だけを担当する。apt repository 追加、package install、Ghostty install、`rustup` install、dotfiles link の実装詳細は個別 script 側に置く。Claude Code は公式 native installer を使うので、`scripts/common/` の user-level install step として管理する。

## macOS 最短手順

```sh
./scripts/mac/setup.sh
```

`scripts/mac/setup.sh` は orchestrator だけを担当する。Homebrew の導入確認、`sudo darwin-rebuild switch --flake ./nix#KokiAoyagi`、APM の user-level install、dotfiles link の実装詳細は個別 script 側に置く。`cmux` 自体の package ownership は `nix/modules/darwin/homebrew.nix` にある。ghostty config は Home Manager module として repo に残すが、macOS では Homebrew install 対象にしない。

この repo では `scripts/mac/`, `scripts/linux/`, `scripts/common/` の実体 path をそのまま使う。

手動 step:

```sh
sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake ./nix#KokiAoyagi
```

初回は `darwin-rebuild` がまだ無いことがある。その場合は上の command で一度 `nix-darwin` を適用してから、以後は `./scripts/mac/setup.sh` を再実行する。

`gcloud` を使うなら追加でこれを実行する。

```sh
gcloud init
```

## Script 一覧

### `linux/setup.sh`

- 役割: Linux bootstrap の入口
- 実行順: `linux/install-packages.sh core` → 必要なら `linux/install-packages.sh linux-extra` → 必要なら `linux/install-ghostty.sh` → `linux/install-rustup.sh` → `common/link-dotfiles.sh`
- やらないこと: `home-manager switch`、Docker daemon の post-install 調整、`gcloud init`
- 例: `./scripts/linux/setup.sh`, `./scripts/linux/setup.sh --with-docker`, `./scripts/linux/setup.sh --with-ghostty`

### `mac/setup.sh`

- 役割: macOS bootstrap の入口
- 実行順: `mac/install-homebrew.sh` → `mac/apply-nix-darwin.sh` → `common/install-apm.sh` → `common/link-dotfiles.sh`
- やらないこと: `darwin-rebuild` 初回導入の完全自動化、GUI app 側の認証や初期設定、`gcloud init`
- 例: `./scripts/mac/setup.sh`

### `mac/install-homebrew.sh`

- 役割: macOS の Homebrew installer
- やること: macOS 判定、既存 `brew` の skip、未導入時のみ Homebrew 公式 installer 実行
- やらないこと: Homebrew formula / cask の適用、`darwin-rebuild` 実行、dotfiles 配布
- 例: `./scripts/mac/install-homebrew.sh`

### `mac/apply-nix-darwin.sh`

- 役割: macOS の `nix-darwin` apply
- やること: macOS 判定、`nix` と `darwin-rebuild` の前提確認、repo root で `sudo darwin-rebuild switch --flake ./nix#KokiAoyagi` 実行
- やらないこと: Nix installer 自体の導入、`darwin-rebuild` 初回導入の完全自動化、dotfiles 配布
- 例: `./scripts/mac/apply-nix-darwin.sh`

### `linux/install-packages.sh`

- 役割: Debian / Ubuntu 向け OS package installer
- profile:
  - `core`: `ca-certificates`, `curl`, `zsh`, `unzip`, `build-essential`, `locales`, `google-cloud-cli`
  - `linux-extra`: Docker 公式 apt repository を登録してから `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`
- やらないこと: `rustup` install、dotfiles 配布、Home Manager 実行
- 例: `./scripts/linux/install-packages.sh core`, `./scripts/linux/install-packages.sh linux-extra`

### `linux/install-rustup.sh`

- 役割: `rustup` の shared installer
- やること: 既存 install の検知、未導入時のみ公式 installer を non-interactive で実行
- やらないこと: `apt` package install、dotfiles 配布、toolchain/channel カスタマイズ
- 例: `./scripts/linux/install-rustup.sh`

### `common/install-claude-code.sh`

- 役割: Claude Code の user-level installer
- やること: 既存 `claude` の skip、`curl` / `bash` 前提確認、公式 native installer の `latest` 実行、install 後の `claude` 確認
- やらないこと: Homebrew / npm install、dotfiles 配布
- 例: `./scripts/common/install-claude-code.sh`

### `common/install-apm.sh`

- 役割: APM の user-level installer
- やること: 既存 `apm` の skip、`curl` / `sh` 前提確認、公式 unix installer 実行、install 後の `apm` 確認
- やらないこと: Homebrew install、APM package deploy、dotfiles 配布
- 例: `./scripts/common/install-apm.sh`

### `linux/install-ghostty.sh`

- 役割: Ubuntu 向け `ghostty` installer
- やること: Ubuntu 判定、既存 `ghostty` の skip、Ghostty docs が案内している Ubuntu installer 実行
- やらないこと: `apt` profile 管理、dotfiles 配布、`ghostty` 設定ファイル管理
- 例: `./scripts/linux/install-ghostty.sh`

### `common/link-dotfiles.sh`

- 役割: 明示的に列挙した repo ファイルの link と terminfo compile
- やること: `~/.apm/apm.yml` の明示 link、legacy link cleanup、terminfo compile
- やらないこと: `~/.config` 配下の配布(Home Manager 管理領域)、package install
- 例: `./scripts/common/link-dotfiles.sh`

### `../tests/run.sh`

- 役割: `tests/` 配下の shell / Neovim テストの一括実行
- 例: `./tests/run.sh`

## 推奨手順

Linux は上の「Linux 最短手順」、macOS は「macOS 最短手順」がそのまま推奨手順。
