# Dotfiles

macOS / Linux の user environment を同じ `nix/flake.lock` で管理する。
macOS は nix-darwin + zsh、Linux (Debian / Ubuntu、aarch64) は standalone
Home Manager + Bash を使う。

- 全体の導入手順: この README
- package ownership / 更新 / rollback: [nix/README.md](nix/README.md)
- bootstrap script: [scripts/README.md](scripts/README.md)
- shell: [docs/shell-guide.md](docs/shell-guide.md)
- runtime: [docs/mise-guide.md](docs/mise-guide.md)

## 共通の前提

clone 先は `~/Documents/repos/personal/dotfiles`。
Nix 自体は手動で導入し、`nix-command` / `flakes` を有効にする。
Linux の初回 Home Manager は、この repo の lock にあるものを使う。

```sh
mkdir -p ~/Documents/repos/personal
git clone <your-dotfiles-repo-url> ~/Documents/repos/personal/dotfiles
cd ~/Documents/repos/personal/dotfiles
nix --version
```

## Linux Setup

ホストの開発基盤を apt で入れる。Docker / Ghostty は任意。

```sh
./scripts/linux/setup.sh
# Docker も必要なら:
./scripts/linux/setup.sh --with-docker
# Ubuntu Desktop で Ghostty も必要なら:
./scripts/linux/setup.sh --with-ghostty
# 両方必要なら:
./scripts/linux/setup.sh --with-docker --with-ghostty
```

既に zsh を login shell にしている場合は `chsh -s /bin/bash` を実行しておく。
設定反映では `.bashrc` / `.profile` / `.bash_profile` を Home Manager が管理する。
初回は既存ファイルを backup する。

```sh
nix run ./nix#homeConfigurations.kokiaoyagi.config.programs.home-manager.package -- \
  -b before-dotfiles switch --flake ./nix#kokiaoyagi
```

以降の反映:

```sh
home-manager switch --flake ./nix#kokiaoyagi
```

新しい Bash を開き、repo のルートで共通の user setup を行う。

```sh
./scripts/common/setup-user.sh
```

AWS CLI / Google Cloud CLI / Herdr / prek / Node.js 24 は Nix が導入する。
以前 apt で入れた Google Cloud CLI は自動削除しない。`type -a gcloud` で
Nix 版の利用を確認してから、不要なら apt 版と専用 repository を手動で整理する。

## macOS Setup

```sh
./scripts/mac/setup.sh
```

初回で `darwin-rebuild` が無い場合:

```sh
sudo nix --extra-experimental-features 'nix-command flakes' run --inputs-from ./nix nix-darwin#darwin-rebuild -- switch --flake ./nix#KokiAoyagi
./scripts/mac/setup.sh
```

新しい zsh を開き、repo のルートで共通の user setup を行う。

```sh
./scripts/common/setup-user.sh
```

共通 CLI は Nix、`cmux` / Codex / GUI app は Homebrew。
Markdown Preview（`markdown-preview`）も Homebrew で導入し、Markdown の閲覧と Quick Look に使う。
shell からは `m README.md` で開く。
`mo` は macOS 限定の Nix overlay で管理する。
Herdr は共通 overlay で公式 release を固定し、config は同じ版の
`herdr config check` が build 時に通ったものを配布する。
Ghostty 本体は macOS の Homebrew cask で導入し、config は Home Manager で配置する。
設定の実体は `nix/modules/home/assets/ghostty/config.ghostty`。

## 共通 user setup

`setup-user.sh` は次を順に行う。

1. Nix 版 Node.js 24 / npm と mise / Neovim の存在を確認
2. mise の global runtime を完全な version 指定で install
3. 共通の公式 installer で rustup と Claude Code を導入
4. `Lazy restore` で repo の lockfile に plugin をそろえる

Node は shell hook の起動や `mise install` を必要とせず利用できる。
Nix 版 pnpm を使い、旧 mise Node に依存する Corepack shim は設定反映時に外す。
Yarn が必要な project は、その project 側で tool / version を宣言する。

Claude Code 本体は `scripts/common/install-claude-code.sh` が公式 native installer の
`latest` を使って導入し、普段の更新は Claude Code の自己更新に任せる。
Codex は更新方法の移行を別途判断するまで macOS では Homebrew cask、Linux では:

```sh
npm i -g @openai/codex
```

Rust project は `rust-toolchain.toml` で toolchain / components / targets を宣言する。
Neovim と Claude Code の Rust 支援には、その toolchain の `rust-analyzer` / `rustfmt` / `clippy` が必要。
rustup の新規導入時は stable に `rust-analyzer` / `rust-src` も入れる。
nightly は未導入のときだけ入れ、既存の nightly の更新は `rustup update` に任せる。
それ以外の toolchain と cargo の追加 tool は、必要になったときに入れる。
`gcloud` を利用する場合の認証は `gcloud init` で行う。

## Shared agent instructions

共有 instructions の正本は `agents/AGENTS.md`。
`nix/modules/home/programs/agent-instructions.nix` が Home Manager の `home.file` で
同じファイルを次の 2 箇所へ配布する。

- Claude: `~/.claude/AGENTS.md`
- Codex: `~/.codex/AGENTS.md`

本文の変換・結合処理はない。編集後は通常の設定反映を行う。

```sh
# macOS
sudo darwin-rebuild switch --flake ./nix#KokiAoyagi
# Linux
home-manager switch --flake ./nix#kokiaoyagi
```

Claude Code は v2.1.277 以降の `agents-md` 機能を使う。
`programs/claude/config.nix` で Project instructions を `claude-md-and-agents-md` にし、
プロジェクトの `CLAUDE.md` がある場合も祖先の `~/.claude/AGENTS.md` を読み込む。
Claude 側はホーム配下のプロジェクトからの祖先探索で適用される。
ホーム外のプロジェクトや機能が利用できないセッションには自動適用されない。
更新直後の初回セッションでは機能が有効にならない場合があるため、次のセッションで確認する。
詳しい条件は [Claude Code の AGENTS.md 仕様](https://code.claude.com/docs/en/memory#agentsmd) を参照。

独自の global skill は配置しない。Codex 標準の `.system` と runtime の plugin は
各ツールが管理する。プロジェクト用の skill は、そのプロジェクト内で管理する。
APM と agent-kit への依存はない。

## Tests

```sh
./tests/run.sh
```

shell テストは `sh tests/<name>_test.sh`、Neovim 系は
`nvim --headless -l tests/<name>.lua` で個別に実行できる。

## References

- script ごとの責務: `scripts/README.md`
- `nix/` 配下の責務整理: `nix/README.md`
