# Scripts

全体の導入手順は [repo root README](../README.md)。
`mac/` / `linux/` は OS 固有 bootstrap、`common/` は共通の user-level 処理。
OS package は sudo、runtime / CLI の user install は通常ユーザーで実行する。

## Linux 最短手順

```sh
./scripts/linux/setup.sh
# Home Manager 初回導入・既存 Bash 設定の backup は root README を参照
home-manager switch --flake ./nix#kokiaoyagi
# 新しい Bash を開く
./scripts/common/setup-user.sh
```

Docker: `./scripts/linux/setup.sh --with-docker`
Ubuntu Desktop の Ghostty: `./scripts/linux/setup.sh --with-ghostty`
両方: `./scripts/linux/setup.sh --with-docker --with-ghostty`
Google Cloud CLI は Nix 管理。認証だけ `gcloud init` を手動実行する。

## macOS 最短手順

```sh
./scripts/mac/setup.sh
# 新しい zsh を開く
./scripts/common/setup-user.sh
```

内部で `sudo darwin-rebuild switch --flake ./nix#KokiAoyagi` を実行する。
初回の nix-darwin 導入は root README を参照。
`cmux` は Homebrew cask、`mo` と共通 CLI は Nix。
Markdown Preview（`markdown-preview`）は Homebrew cask で導入する。
Herdr は `nix/overlays/herdr.nix` の公式 release を使う。config の検証は
Home Manager の build 時に行い、既存の server / pane は setup では再起動しない。
Ghostty 本体は Homebrew cask、`ghostty config` は既存の設定資産を Home Manager が配置する。
Google Cloud CLI の認証は必要なら `gcloud init`。

## Script 一覧

| Script | 責務 |
| --- | --- |
| `linux/setup.sh` | core apt → 任意の Docker → 任意の Ghostty → 共通 rustup → terminfo |
| `linux/install-packages.sh core` | ca-certificates / curl / gnupg / Bash / unzip / build-essential / locales / ncurses-bin |
| `linux/install-packages.sh linux-extra` | Docker 公式 apt repository と Docker CE / CLI / containerd / Buildx / Compose |
| `linux/install-ghostty.sh` | Ubuntu 向け community installer。既存 Ghostty があれば skip |
| `mac/setup.sh` | Homebrew 確認 → nix-darwin 反映 → terminfo |
| `mac/install-homebrew.sh` | 未導入時に Homebrew 公式 installer を実行 |
| `mac/apply-nix-darwin.sh` | repo root で nix-darwin を反映。初回導入は担当しない |
| `common/setup-user.sh` | Node 24 確認 → global mise install → rustup → Claude Code → Lazy restore |
| `common/install-rustup.sh` | 未導入時に公式 rustup installer を実行し、stable に `rust-analyzer` / `rust-src` を追加。nightly も未導入なら追加 |
| `common/install-claude-code.sh` | 公式 native installer の latest。cmux 付属 shim だけでは skip しない |
| `common/link-dotfiles.sh` | legacy link cleanup / terminfo compile。config 配布は Home Manager |
| `../tests/run.sh` | shell / Neovim テストの一括実行 |

Claude Code の個別導入は `./scripts/common/install-claude-code.sh`。
Ghostty の個別導入は `./scripts/linux/install-ghostty.sh`。
`setup-user.sh` は Home Manager 適用後の新しい shell で、project override のない
repo root から実行する。runtime install は home directory を基準に行う。
`Lazy restore` は network と build tools を必要とする場合がある。
Rust toolchain の components / targets は project の `rust-toolchain.toml` に宣言する。
login shell 変更、認証、既存 apt Google Cloud CLI の削除は script では行わない。
