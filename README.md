# Dotfiles

この repo は、KokiAoyagi の macOS / Linux user environment の source of truth です。

end-to-end の環境構築手順はこの `README.md` を基準にする。

- `scripts/README.md`: bootstrap script catalog
- `nix/README.md`: `nix/` 配下の source of truth

## Resume

- clone 先は `~/Documents/repos/personal/dotfiles` を前提にする
- Nix 自体の install は手動で行う
- Linux は `./scripts/setup-linux.sh` の後に `home-manager switch`、`mise install`、`npm i -g @openai/codex` まで進める
- Ubuntu Desktop で `ghostty` も必要なら `./scripts/setup-linux.sh --with-ghostty` を使う
- macOS は `./scripts/setup-mac.sh` を入口にし、必要なら `nix-darwin` の初回 fallback を挟む
- macOS の `ghostty` は `nix/modules/darwin/homebrew.nix` の Homebrew cask で管理している

- [Setup Overview](#setup-overview)
- [Linux Setup](#linux-setup)
- [macOS Setup](#macos-setup)
- [References](#references)

## Setup Overview

- clone 先は `~/Documents/repos/personal/dotfiles` を前提にしている
- Linux は standalone Home Manager を使う
- macOS は `nix-darwin` を使う
- Nix 自体の install は手動で行う

### 1. Clone

```sh
mkdir -p ~/Documents/repos/personal
git clone <your-dotfiles-repo-url> ~/Documents/repos/personal/dotfiles
cd ~/Documents/repos/personal/dotfiles
```

### 2. Install Nix Manually

Determinate Nix か公式 Nix installer で Nix を入れる。

Linux では standalone Home Manager も使える状態にする。

```sh
nix --version
home-manager --version
```

## Linux Setup

### 3. Run The Pre-Nix Bootstrap

Docker 不要:

```sh
./scripts/setup-linux.sh
```

Docker も必要:

```sh
./scripts/setup-linux.sh --with-docker
```

Ubuntu Desktop で Ghostty も必要:

```sh
./scripts/setup-linux.sh --with-ghostty
```

Docker と Ghostty の両方が必要:

```sh
./scripts/setup-linux.sh --with-docker --with-ghostty
```

この段階では OS package install、`rustup` install、dotfiles link までを行う。

### 4. Apply Home Manager

```sh
home-manager switch --flake ./nix#kokiaoyagi
```

### 5. Install Mise-Managed Runtimes

```sh
mise install
```

### 6. Confirm Node / npm

```sh
npm -v
```

### 7. Install Codex Manually

`mise` / `npm` が見つからない場合は新しい shell を開いてから再確認する。

```sh
npm i -g @openai/codex
```

### 8. Optional Manual Steps

`gcloud` を使うなら:

```sh
gcloud init
```

login shell を `zsh` に変えるなら:

```sh
chsh -s "$(command -v zsh)"
```

## macOS Setup

### 3. Run The Bootstrap Entrypoint

```sh
./scripts/setup-mac.sh
```

この中で `sudo darwin-rebuild switch --flake ./nix#KokiAoyagi` を通して `nix/modules/darwin/homebrew.nix` の Homebrew cask 群も適用される。`ghostty` はここで入る。

### 4. If `darwin-rebuild` Is Missing On First Run

初回は `darwin-rebuild` がまだ無いことがある。その場合は先にこれを実行する。

```sh
sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake ./nix#KokiAoyagi
./scripts/setup-mac.sh
```

### 5. Optional Manual Steps

`gcloud` を使うなら:

```sh
gcloud init
```

## References

- script ごとの責務: `scripts/README.md`
- `nix/` 配下の責務整理: `nix/README.md`
