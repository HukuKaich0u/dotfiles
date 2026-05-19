# Dotfiles

この repo は、KokiAoyagi の macOS / Linux user environment の source of truth です。

end-to-end の環境構築手順はこの `README.md` を基準にする。

- `scripts/README.md`: bootstrap script catalog
- `nix/README.md`: `nix/` 配下の source of truth

## Setup Overview

前提:

- clone 先は `~/Documents/repos/personal/dotfiles` を前提にしている
- Linux は standalone Home Manager を使う
- macOS は `nix-darwin` を使う
- Nix 自体の install は手動で行う

## Linux Setup

### 1. Clone

```sh
mkdir -p ~/Documents/repos/personal
git clone <your-dotfiles-repo-url> ~/Documents/repos/personal/dotfiles
cd ~/Documents/repos/personal/dotfiles
```

### 2. Install Nix Manually

Determinate Nix か公式 Nix installer で Nix を入れる。  
そのうえで standalone Home Manager が使える状態にする。

確認:

```sh
nix --version
home-manager --version
```

### 3. Run The Pre-Nix Bootstrap

Docker 不要:

```sh
./scripts/setup-linux.sh
```

Docker も必要:

```sh
./scripts/setup-linux.sh --with-docker
```

この段階では OS package install、`rustup` install、dotfiles link までを行う。  
Codex install はまだやらない。

### 4. Apply Home Manager

```sh
home-manager switch --flake ./nix#kokiaoyagi
```

### 5. Install Mise-Managed Runtimes

`mise` が見つからない場合は新しい shell を開いてから実行する。

```sh
mise install
```

### 6. Confirm Node / npm

```sh
npm -v
```

`npm` が見つからない場合も、新しい shell を開いてから再確認する。

### 7. Install Codex Manually

Linux では Codex 本体は shell script ではなく手動 install にする。  
理由は、Codex が `mise` 管理の Node / npm に依存するため。

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

### 1. Clone

```sh
mkdir -p ~/Documents/repos/personal
git clone <your-dotfiles-repo-url> ~/Documents/repos/personal/dotfiles
cd ~/Documents/repos/personal/dotfiles
```

### 2. Install Nix Manually

Determinate Nix か公式 Nix installer で Nix を入れる。

確認:

```sh
nix --version
```

### 3. Run The Bootstrap Entrypoint

```sh
./scripts/setup-mac.sh
```

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
