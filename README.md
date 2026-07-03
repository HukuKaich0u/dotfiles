# Dotfiles

この repo は、KokiAoyagi の macOS / Linux user environment の source of truth です。

end-to-end の環境構築手順はこの `README.md` を基準にする。

- `scripts/README.md`: bootstrap script catalog
- `nix/README.md`: `nix/` 配下の source of truth

## Resume

- clone 先は `~/Documents/repos/personal/dotfiles` を前提にする
- Nix 自体の install は手動で行う
- Linux は `./scripts/linux/setup.sh` の後に `home-manager switch`、`mise install`、`./scripts/common/install-claude-code.sh`、`npm i -g @openai/codex` まで進める
- Ubuntu Desktop で `ghostty` も必要なら `./scripts/linux/setup.sh --with-ghostty` を使う
- macOS は `./scripts/mac/setup.sh` を入口にし、必要なら `nix-darwin` の初回 fallback を挟む。`apm` の未導入時はこの setup が公式 installer で入れる
- `ghostty` の install は Linux では `scripts/linux/install-ghostty.sh` が担当する
- macOS では `cmux` を `nix/modules/darwin/homebrew.nix` の Homebrew cask で管理する
- `mo` は当面 macOS の Homebrew brew だけで管理し、Linux にはまだ導入しない
- `ghostty` の config は Home Manager で管理し、repo に残す

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
./scripts/linux/setup.sh
```

Docker も必要:

```sh
./scripts/linux/setup.sh --with-docker
```

Ubuntu Desktop で Ghostty も必要:

```sh
./scripts/linux/setup.sh --with-ghostty
```

Docker と Ghostty の両方が必要:

```sh
./scripts/linux/setup.sh --with-docker --with-ghostty
```

この段階では OS package install、必要なら `ghostty` install、`rustup` install、dotfiles link までを行う。`ghostty` の config 自体は次の `home-manager switch` で反映する。

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

### 7. Install Claude Code

```sh
./scripts/common/install-claude-code.sh
```

Claude Code の install ownership は macOS / Linux ともこの script が持つ。公式 native installer を `latest` 指定で実行する。

install 後に `claude` が見つからない場合は新しい zsh を開いて PATH を再確認する。

### 8. Install Codex Manually

`mise` / `npm` が見つからない場合は新しい shell を開いてから再確認する。

```sh
npm i -g @openai/codex
```

### 9. Optional Manual Steps

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
./scripts/mac/setup.sh
```

この中で `sudo darwin-rebuild switch --flake ./nix#KokiAoyagi` を通して `nix/modules/darwin/homebrew.nix` の Homebrew cask / brew 群も適用される。`cmux` と `mo` の install はここで入る。`mo` は当面 macOS のみで管理し、Linux にはまだ導入しない。`ghostty` config は Home Manager 側の設定資産として repo に残すが、macOS では Homebrew install しない。`apm` が未導入なら同じ setup 内で公式 unix installer を実行する。

### 4. If `darwin-rebuild` Is Missing On First Run

初回は `darwin-rebuild` がまだ無いことがある。その場合は先にこれを実行する。

```sh
sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake ./nix#KokiAoyagi
./scripts/mac/setup.sh
```

### 5. Optional Manual Steps

`gcloud` を使うなら:

```sh
gcloud init
```

## Tests

```sh
./tests/run.sh
```

shell テストは `sh tests/<name>_test.sh`、Neovim 系は
`nvim --headless -l tests/<name>.lua` で個別に実行できる。

## References

- script ごとの責務: `scripts/README.md`
- `nix/` 配下の責務整理: `nix/README.md`
