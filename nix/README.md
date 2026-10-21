# Nix Configuration SoT

この README は `nix/` 配下の責務と運用の source of truth。
全体の導入手順は [repo root README](../README.md) を参照する。

## Goal

- macOS は nix-darwin + Home Manager、Linux は standalone Home Manager
- macOS の対話 shell は zsh、Linux は distro の `/bin/bash`
- 両 OS は同じ `flake.lock` / nixpkgs / Home Manager を使う
- 共通設定は `modules/home/`、OS 固有の設定は `modules/darwin/` / `modules/linux/`
- Node.js 24、共通 CLI、Neovim の LSP / formatter は nixpkgs で固定
- mise の global runtime は完全な version を指定。Node は project override のみ
- Neovim plugin は repo の `lazy-lock.json` を共有し、`Lazy restore` で反映

## Linux Shortest Path

```sh
./scripts/linux/setup.sh
# 初回は repo の lock に対応する Home Manager を使い、既存設定を backup する。
nix run ./nix#homeConfigurations.kokiaoyagi.config.programs.home-manager.package -- \
  -b before-dotfiles switch --flake ./nix#kokiaoyagi
# 新しい Bash を開いてから:
./scripts/common/setup-user.sh
```

Docker は `./scripts/linux/setup.sh --with-docker`、Ubuntu Desktop の Ghostty は
`./scripts/linux/setup.sh --with-ghostty`、両方なら
`./scripts/linux/setup.sh --with-docker --with-ghostty`。
以降の反映は `home-manager switch --flake ./nix#kokiaoyagi`。
既に zsh を login shell にしていた場合、反映前に `chsh -s /bin/bash` を実行する。

## macOS Shortest Path

```sh
./scripts/mac/setup.sh
# 新しい zsh を開いてから:
./scripts/common/setup-user.sh
```

`scripts/mac/setup.sh` は Homebrew install、
`sudo darwin-rebuild switch --flake ./nix#KokiAoyagi`、terminfo の準備を行う。
初回で `darwin-rebuild` が無い場合は、repo の input に固定した版で導入する。

```sh
sudo nix --extra-experimental-features 'nix-command flakes' run --inputs-from ./nix nix-darwin#darwin-rebuild -- switch --flake ./nix#KokiAoyagi
./scripts/mac/setup.sh
```

`cmux` / Codex / GUI app は `modules/darwin/homebrew.nix`。
Markdown Preview（`markdown-preview`）は Markdown 閲覧用の app / Quick Look 拡張として Homebrew で導入する。
`mo` は `modules/darwin/packages.nix` と Nix overlay。
Ghostty 本体は macOS の Homebrew cask で導入する。
`ghostty config` は `modules/home/assets/ghostty/config.ghostty` を正本とし、
Home Manager が `~/Library/Application Support/com.mitchellh.ghostty/config` に配置する。
`gcloud` の認証は両 OS とも `gcloud init`。

## Responsibility

| 場所 | 責務 |
| --- | --- |
| `flake.nix` | input と OS の入口の配線。package 一覧や program 設定は置かない |
| `lib/nixpkgs.nix` | 共通の nixpkgs config / overlay |
| `overlays/` | 既存 package の修正、独自 package |
| `modules/home/default.nix` | 共通 import / stateVersion |
| `modules/home/packages.nix` | 両 OS の汎用 CLI / Node.js 24 / pnpm |
| `modules/home/programs/` | program ごとの設定。1 program = 1 module |
| `modules/home/assets/` | Neovim Lua / lockfile、tmux、terminal、Cursor 等の実ファイル |
| `modules/darwin/default.nix` | macOS の user、zsh、macOS 専用 import |
| `modules/darwin/packages.nix` | macOS だけで使う Nix package |
| `modules/darwin/system.nix` | nix-darwin の machine 設定、root GC / optimise |
| `modules/darwin/home-manager.nix` | nix-darwin と Home Manager の bridge |
| `modules/darwin/homebrew.nix` | Homebrew に残す OS 連携 / GUI / 外部更新ツール |
| `modules/linux/default.nix` | Linux user / home directory / import |
| `modules/linux/bash.nix` | Bash completion / 履歴 / interactive 初期化 |
| `modules/linux/packages.nix` | Linux 専用の Nix package |

新規 module は上記へ配置し、`nix/home-manager/` 等の別階層を作らない。
`home.stateVersion` / `system.stateVersion` は更新のために変更しない。

## Package ownership

- 共通 Nix CLI: AWS CLI (`awscli2`)、Google Cloud CLI (`google-cloud-sdk`)、Herdr、prek、
  Node.js 24 (`nodejs_24`)、pnpm、および `modules/home/packages.nix` の一覧
- Herdr は `overlays/herdr.nix` で公式 release `0.9.5` と platform ごとの SHA-256 を固定
- macOS 専用 Nix CLI: Gauche、LLVM、Marp CLI、PHP、QEMU、GNU time、pngpaste、
  ascii-image-converter、mo
  (GNU time は従来の `gtime` command も提供する)
- Homebrew: cmux、Codex、GUI app、dnsmasq、terminal-notifier、既存の native library 群
- apt: Bash、curl、gnupg、build-essential、locales、terminfo compiler、任意の Docker
- mise: Bun `1.3.14`、Go `1.26.6`、Java `25.0.2`、Lua `5.4.8`、Terraform `1.12.2`
- Rust: 共通の公式 rustup installer。project の `rust-toolchain.toml` で固定
- Python: uv を Nix で導入し、project の環境 / lockfile で管理
- Claude Code: `scripts/common/install-claude-code.sh` の公式 native installer、自己更新。
  本体は Nix / Homebrew に置かない
- Codex: 当面 macOS は Homebrew cask、Linux は `npm i -g @openai/codex`

mise の version は移行時の Mac の選択値を完全な version として固定したもの。
Node 24 は Home Manager の通常の PATH に入り、mise hook に依存しない。
project が mise で別 Node を要求した場合は、その project の指定を優先する。
旧 activation が `~/.local/bin` に作った mise Node 依存の Corepack symlink だけを除去し、
pnpm は Nix に統一する。Yarn 等は必要な project 側で宣言する。

Linux の旧 apt Google Cloud CLI は自動削除しない。`type -a gcloud` で Nix 版を確認し、
不要になった apt package / 専用 apt source は手動で整理する。
Homebrew の `cleanup = "uninstall"` により、一覧から移した formula は次の反映で外れる。
今回の編集だけでは package の削除や環境反映は行わない。

### Nix package の信頼と更新

nixpkgs に package があることと、upstream がその配布を公式サポートすることは別。
既存 CLI の移行では対応 platform / package source / version と実動作を確認する。
upstream の自己更新機能は Nix store を変更できないので、Nix 管理の CLI は
`brew upgrade` やツール自身の updater では更新せず、flake を更新して反映する。

`flake.lock` を更新しない限り、nixpkgs の branch の最新状態には勝手に追従しない。
セキュリティ修正も自動では取り込まれないので、定期的に次の更新手順を実行する。

## Shell

alias と user PATH は `modules/home/programs/shell.nix` が正本。
`home.shellAliases` を Bash / zsh の両方へ反映する。
macOS では `m` を Homebrew の `mdp`（Markdown Preview）へ割り当てる。

`modules/home/programs/shell-integrations.nix` は対象 OS の shell 用に mise / direnv /
zoxide / Starship の初期化コードを build 時に生成する。hook の二重登録は行わない。
Yazi の `yy` は Home Manager の Bash / zsh integration が生成する。

Linux は Home Manager が `.bashrc` / `.profile` / `.bash_profile` を配布する。
Bash completion、履歴10,000件、重複・先頭空白の除外、prompt ごとの履歴共有、
Emacs keymap、Esc+Enter の改行入力を設定する。
Bash 標準には zsh-autosuggestions / syntax highlighting の同等機能を追加していない。
端末固有設定は Linux が `~/.config/bash/local.bash`、macOS が
`~/.config/zsh/local.zsh`。login shell の変更は Home Manager では実行しない。

## Neovim

- Lua: `modules/home/assets/nvim/`
- 本体 / LSP / formatter: `modules/home/programs/nvim.nix` と共通 package
- plugin: `modules/home/assets/nvim/lazy-lock.json`

Mason は使わず、LSP / formatter を Nix に統一する。rust-analyzer / rustfmt / clippy は
project の rustup toolchain に合わせる。既存 Mason data は自動削除しない。
Neovim wrapper で PATH を上書きせず、project / mise / rustup の選択を維持する。

Home Manager は共通 lockfile を writable な `$XDG_STATE_HOME/nvim/lazy-lock.json`
(default: `~/.local/state/nvim/lazy-lock.json`) へ配置する。
反映後の `./scripts/common/setup-user.sh` または `:Lazy restore` で checkout をそろえる。
初回の lazy.nvim bootstrap 自体も共通 lockfile の commit を使う。

plugin を更新するときは `:Lazy update` で確認後、state 側の lockfile を
`nix/modules/home/assets/nvim/lazy-lock.json` へコピーして diff とテストを確認する。
反映前の state の変更は端末ローカル。次回 switch で repo の lockfile に戻る。
詳細は `modules/home/assets/nvim/docs/coding-guide.md`。

## Herdr

本体は `overlays/herdr.nix`、設定は `modules/home/assets/herdr/config.toml`。
nixpkgs の版が config schema に追いつかない場合も、共通 overlay で両 OS の
version をそろえる。公式 Linux binary は static link、macOS binary は署名を
維持するため strip せずに配置する。

Home Manager は配布前に、同じ package の `herdr config check` を実行する。
未知の設定や keybinding の衝突は build を失敗させ、defaults への暗黙の
fallback を防ぐ。config は Nix 管理の read-only ファイルなので、変更は repo に
反映する。GUI からの永続保存は使わない。

更新時は release の version / asset の SHA-256 を overlay で更新し、
`sh tests/herdr_deploy_test.sh` と対象 OS の build を確認してから switch する。
`herdr --version` は PATH 上の CLI、`herdr status server` は稼働中 server の版を
確認する。switch だけでは server / client は入れ替わらない。
`herdr server stop` は pane のプロセスも終了するので、作業を保存してから実行し、
新しい `herdr` で起動し直す。同じ版のまま config だけを変えた場合は
`herdr server reload-config` で反映する。

## Other program configuration

- `cursor.nix`: macOS の settings / keybindings / tasks を repo への out-of-store symlink で配布。
  拡張は一覧から不足分のみ導入する。GUI の変更は git diff で確認する
- `herdr.nix`: 検証済み config.toml のみ配布。`assets/herdr/key-bind.md` は repository-only
- `hunk.nix`: Home Manager module の settings で管理
- `agent-instructions.nix`: repo root `agents/AGENTS.md` を
  `~/.claude/AGENTS.md` / `~/.codex/AGENTS.md` へ同じ内容で配布
- `modules/home/programs/claude/`: writable な settings.json に管理キーを merge。
  `agents-md` plugin の設定もここで管理する
- `codex/config.nix`: writable な config.toml を生成。次回 switch で管理値に戻す
- `mo-markdown-viewer.nix`: k1LoW/mo の macOS ARM release を固定。
  nixpkgs の同名の別ツールを上書きするため、Linux で使う際は専用 attr に分ける
- `direnv-no-zsh-check.nix`: Darwin の build に限って upstream の zsh test を回避

## Updating Inputs

nixpkgs / nix-darwin / Home Manager は互換性のため一緒に更新する。
repo ルートから実行する。

```sh
nix flake update --flake ./nix nixpkgs nix-darwin home-manager
nix build ./nix#darwinConfigurations.KokiAoyagi.system --no-link
./tests/run.sh
```

Linux 上でも build / tests を確認する。

```sh
nix build ./nix#homeConfigurations.kokiaoyagi.activationPackage --no-link
./tests/run.sh
```

この flake の Linux は `aarch64-linux` 固定。x86_64 VM を使う場合は entry を追加する。
Mac での Linux 構成の evaluation は、Linux 上の build / 動作確認の代わりにはならない。
`nix flake check` だけでは独自の homeConfigurations / darwinConfigurations の
build を網羅しないため、上記 target を明示する。

通過後に各 OS の switch と `setup-user.sh` を実行し、新しい shell で確認する。
失敗した場合は switch せず lockfile / 設定の差分を見直す。

## Rollback

Nix 管理 package / 設定の直前の generation に戻す例:

```sh
# macOS
sudo darwin-rebuild switch --rollback
# Linux: home-manager generations で一覧を確認し、戻したい generation の activate を実行
home-manager generations
```

mise の install、rustup、Claude Code、Homebrew、Neovim の plugin checkout は
Nix generation の rollback だけでは戻らない。
plugin は戻した設定の lockfile で `Lazy restore`、mise は戻した完全な version で
`setup-user.sh` を再実行する。Homebrew app / 自己更新する CLI は別に更新状態を確認する。
GC で消した generation には戻れない。macOS の保持期間は30日。

## Rules

構成を変えるときはこの README と root / scripts / tool guides を同時に更新する。
新規ファイルを Git flake の評価対象にしてから検証する。
実機で確認できないものは、evaluation / build / runtime のどこまで確認したかを区別する。
