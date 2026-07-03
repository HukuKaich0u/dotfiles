# Nix Configuration SoT

この README は `nix/` 配下の **source of truth** です。

- いま実際にどう置かれているか、ではなく
- これから **どの構成に寄せるか**
- どこに何を書くべきか

を定義します。

今後 `nix/` 配下を触るときは、まずこの README に従います。

zero-to-working の全体手順は repo root の `README.md` を参照。
この README は `nix/` 配下の source of truth と責務整理に集中する。

## Goal

- macOS は `nix-darwin` を入口に使う
- Linux は standalone `home-manager` を入口に使う
- 共通の user 設定は `modules/home/` に寄せる
- OS 固有差分は `modules/darwin/` と `modules/linux/` に閉じ込める
- overlay と helper は `overlays/` と `lib/` に分ける
- `flake.nix` は入口の配線だけを担当し、設定本体を持たない

## Linux Shortest Path

Linux の最短 bootstrap は 2 段階です。

```sh
./scripts/linux/setup.sh
home-manager switch --flake ./nix#kokiaoyagi
```

Ubuntu Desktop で Ghostty も必要なら最初の command だけ `./scripts/linux/setup.sh --with-ghostty` に置き換える。Docker も必要なら `./scripts/linux/setup.sh --with-docker`、両方必要なら `./scripts/linux/setup.sh --with-docker --with-ghostty` を使う。`scripts/linux/setup.sh` は OS package, `rustup`, dotfiles link、必要なら Ghostty install までを担当し、Ghostty config を含む Nix 側の反映は `home-manager switch` を明示的に続ける。

## macOS Shortest Path

macOS の最短 bootstrap は、まず入口 script を実行してから必要な手動 step を続ける。

```sh
./scripts/mac/setup.sh
```

`scripts/mac/setup.sh` は Homebrew install, `sudo darwin-rebuild switch --flake ./nix#KokiAoyagi`, dotfiles link を順に呼ぶ orchestrator として保つ。`cmux` の install は `modules/darwin/homebrew.nix` の Homebrew cask が担当する。ghostty config は Home Manager module として repo に残すが、macOS では Homebrew install 対象にしない。

初回は `darwin-rebuild` command がまだ存在しない場合がある。その場合の手動 step はこれ。

```sh
sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin -- switch --flake ./nix#KokiAoyagi
./scripts/mac/setup.sh
```

追加の手動 step:

```sh
gcloud init
```

## Canonical Structure

将来的な正規構成はこれです。

```text
nix/
├── README.md
├── flake.nix
├── flake.lock
├── lib/
│   └── *.nix
├── overlays/
│   ├── default.nix
│   └── direnv-no-zsh-check.nix
└── modules/
    ├── home/
    │   ├── default.nix
    │   ├── packages.nix
    │   ├── programs/
    │   │   ├── agent-skills/
    │   │   ├── bacon.nix
    │   │   ├── claude/
    │   │   ├── codex/
    │   │   ├── direnv.nix
    │   │   ├── gh.nix
    │   │   ├── git.nix
    │   │   ├── ghostty.nix
    │   │   ├── mise.nix
    │   │   ├── nvim.nix
    │   │   ├── starship.nix
    │   │   ├── tmux.nix
    │   │   ├── wezterm.nix
    │   │   ├── yazi.nix
    │   │   ├── zoxide.nix
    │   │   └── zsh.nix
    │   └── assets/
    │       ├── ghostty/
    │       ├── nvim/
    │       ├── tmux/
    │       └── wezterm/
    ├── darwin/
    │   ├── default.nix
    │   ├── packages.nix
    │   ├── system.nix
    │   ├── home-manager.nix
    │   └── homebrew.nix
    └── linux/
        ├── default.nix
        ├── packages.nix
        └── zsh.nix
```

## Responsibility

### `flake.nix`

入口定義だけを書く場所です。

- `darwinConfigurations."KokiAoyagi"`
- `homeConfigurations."kokiaoyagi"`
- shared input / helper wiring

ここに program 設定や package 一覧を書かないこと。

### `lib/`

shared helper を置く場所です。

例:

- `mkPkgs`
- shared attr builder
- path helper

複数 module から使うロジックだけを置きます。単一ファイル専用のロジックは元の module に残します。

### `overlays/`

overlay の置き場です。

- 個別 overlay は 1 file 1 responsibility
- `default.nix` で束ねる

例:

- `direnv-no-zsh-check.nix`

`common/` のような曖昧な名前ではなく、overlay は overlay として明示します。

### `modules/home/`

cross-platform な Home Manager 設定の本体です。

#### `modules/home/default.nix`

共通 Home Manager module の入口です。

- shared import 一覧
- `home.stateVersion`
- `programs.home-manager.enable`
- 共通設定の配線

#### `modules/home/packages.nix`

OS を問わず入れたい user package を置きます。

例:

- `ast-grep`
- `bat`
- `clang-tools`
- `ffmpeg`
- `fzf`
- `git`
- `ripgrep`
- `fd`
- `ghostscript`
- `gnumake`
- `lazygit`
- `imagemagick`
- `lua-language-server`
- `luarocks`
- `pipx`
- `pkg-config`
- `pnpm`
- `postgresql_17`
- `tectonic`
- `tmux`
- `tombi`
- `tree`
- `tree-sitter`
- `uv`

package 一覧を `default.nix` に直接肥大化させないこと。

#### `modules/home/programs/`

各ツールごとの Home Manager module を置きます。

- 1 program = 1 file
- `programs.<name>` の設定はここ
- 特定ツールの `xdg.configFile` もここ

例:

- `git.nix`
- `gh.nix`
- `ghostty.nix`
- `claude/`
- `codex.nix`
- `mise.nix`
- `nvim.nix`
- `tmux.nix`
- `zsh.nix`

#### `modules/home/assets/`

program module から参照される実ファイル群を置きます。

例:

- Neovim の Lua / lockfile
- tmux の `tmux.conf`
- Ghostty の `config`
- WezTerm の Lua config

Lua や tmux conf のような asset を `programs/` と同じ階層に散らさないこと。

#### `modules/home/programs/codex/`

Codex 固有の Home Manager module 群です。

- `config.nix`
  - `~/.codex/config.toml` を activation で実ファイル生成する
- `default.nix`
  - Codex module の束ね役

AGENTS.md などの指示ファイルと skills の配布は APM (`~/.apm/apm.yml`) が担当し、
Nix はここでは config.toml の生成だけを持ちます。

#### `modules/home/programs/claude/`

Claude 固有の Home Manager module 群です。

- `config.nix`
  - `~/.claude/settings.json` は activation で既存 JSON に Nix 側の設定キーを merge する
- `default.nix`
  - Claude module の束ね役

CLAUDE.md などの指示ファイルと skills の配布は APM (`~/.apm/apm.yml`) が担当します。
Claude Code 本体の install ownership はここではなく platform ごとに分けます。

#### `modules/home/programs/agent-skills/`

agent skills の Home Manager 側の接着層です。skill 本体の配布 SoT は APM
(`~/.apm/apm.yml`) で、Nix は「配布先ディレクトリの準備」と「external
collection の pin 配布」だけを持ちます。

- `skill-dirs.nix`
  - `~/.claude/skills/` と `~/.agents/skills/` を実ディレクトリとして準備する
  - 旧構成の dirlink symlink を activation で掃除する
- `external/`
  - upstream pin のまま扱う skill collection を置く
  - `superpowers-src.nix` が source derivation を返し、`superpowers.nix` が
    `~/.agents/skills/superpowers`(dirlink)と `~/.claude/skills/<leaf>`
    (flatten)の両方へ link する
  - Claude Code は `~/.claude/skills/<name>/SKILL.md` を 1 階層しか見ないため、
    collection は leaf ごとに展開して link する
- `lib.nix`
  - SKILL.md を持つ leaf directory を再帰探索する共有 helper
- `default.nix`
  - skills module の束ね役

### `modules/darwin/`

macOS 固有の責務を置く場所です。

#### `modules/darwin/default.nix`

macOS 用 Home Manager wrapper です。

- `home.username`
- `home.homeDirectory`
- `modules/home/default.nix` の import
- macOS 固有の user-only import

#### `modules/darwin/packages.nix`

macOS でだけ Home Manager package に載せたいものを置きます。

例:

- `pngpaste`
- `ascii-image-converter`

Homebrew と Home Manager の境界を曖昧にしないため、darwin 専用 package はここへ寄せます。

#### `modules/darwin/system.nix`

`nix-darwin` の machine-level 設定です。

例:

- `system.stateVersion`
- `system.configurationRevision`
- `system.primaryUser`
- `users.users.<name>.home`
- `system.defaults`
- `security`

shell や git のような user 設定はここに書かないこと。

#### `modules/darwin/home-manager.nix`

`nix-darwin` から Home Manager へ接続する bridge です。

- `home-manager.useGlobalPkgs`
- `home-manager.useUserPackages`
- `home-manager.users.<name> = ./default.nix`

ここに日常設定本体は書かないこと。

#### `modules/darwin/homebrew.nix`

Homebrew 専用です。

- taps
- brews
- casks

現状の Codex install もここで管理します。Claude Code は公式 native installer 側に寄せます。

- `codex` の install は Homebrew cask
- `mo` は当面 macOS の Homebrew brew だけで管理する
- Claude の設定ファイル配布は `modules/home/programs/claude/`
- Codex の設定ファイル配布は `modules/home/programs/codex/`

Nix package で足りるものはまず Nix を優先し、Homebrew は macOS 依存や運用上必要なものだけに寄せます。
`k1LoW/mo` は nixpkgs の `mo` と別物なので、Linux へ入れる場合は `k1low-mo` のような名前で overlay/package 化してから `modules/linux/packages.nix` に追加する。

## Codex Layout

Codex まわりは install / config / prompt assets を分けて考えます。

### install

- macOS: `modules/darwin/homebrew.nix`
- Linux: `npm i -g @openai/codex`(repo root README.md の手順を正とする)

### config

- `modules/home/programs/codex/config.nix`
- `~/.codex/config.toml` を Home Manager activation で実ファイル生成

現状 `config.toml` に入れている設定はこれです。

```toml
model = "gpt-5.4"
approval_policy = "on-request"
model_reasoning_effort = "medium"
web_search = "live"
personality = "pragmatic"

[tui.keymap.global]
open_external_editor = []
```

これはプロンプト入力中に external editor を開く操作を無効化する設定です。

`config.toml` は symlink ではなく writable な実ファイルとして生成するので、Codex 自身が trust 状態などを書き込めます。ただし次回 `home-manager switch` では Nix 側の初期値で上書きされます。

### prompt assets / adapters

- repo root `/.codex/AGENTS.md`
- repo root `/.claude/`
- repo root `/.agents/skills/`

役割はこう分けます。

- `/.codex/`
  - Codex 用 adapter 層
  - `AGENTS.md` のような Codex 向け入口を置く
- `/.claude/`
  - Claude 用 adapter 層
- `/.agents/`
  - cross-tool な agent / skill 資産の SoT
  - `AGENTS.md` の実体
  - `skills/` の local SoT

現状の `/.codex/AGENTS.md` は `/.agents/AGENTS.md` への tracked symlink です。
つまり adapter 層の入口だけ `/.codex/` に残し、実体は `/.agents/` に寄せます。

グローバル(`~/.codex/AGENTS.md` 等)への配布は APM (`~/.apm/apm.yml`) が担当し、
repo 内の adapter はこのリポジトリ自体で作業するときのプロジェクトレベル指示として機能する。

## Claude Layout

Claude まわりも install / config / prompt assets を分けて考えます。

### install

- macOS: `scripts/common/install-claude-code.sh`
- Linux: `scripts/common/install-claude-code.sh`

macOS / Linux とも `./scripts/common/install-claude-code.sh` が公式 native installer を `latest` 指定で実行する。普段の shell が zsh でも installer script は `bash` で実行する。

### config

- `modules/home/programs/claude/config.nix`
- `~/.claude/settings.json` は丸ごと置換ではなく、既存 JSON に Nix 側の設定キーを merge

### prompt assets / adapters

- repo root `/.claude/`
- repo root `/.agents/AGENTS.md`

`/.claude/CLAUDE.md` は Claude 用 adapter 層の入口で、現状は `/.agents/AGENTS.md` への tracked symlink です。

### skills 配布

- agent-kit の skills / instructions: APM (`~/.apm/apm.yml`) が
  `~/.claude/skills/` と `~/.agents/skills/` へ配布する
- external collection (superpowers): `modules/home/programs/agent-skills/external/`
  が upstream pin から link する

運用ルール:

- skill の追加・削除は agent-kit repo と `.apm/apm.yml` で行う
- 大きい skill collection は `external/` で upstream pin を検討する
- 現状 upstream pin なのは `superpowers` だけ

## Linux zsh

Linux は standalone Home Manager を使っているので、login shell の変更までは Nix で自動化しません。

- zsh の install は `scripts/linux/install-packages.sh core`
- `google-cloud-cli` の install も `scripts/linux/install-packages.sh core`
- default shell の変更は手動で `chsh -s "$(command -v zsh)"`
- shell 設定ファイルは repo root の `zsh/` を source of truth にする
- `modules/linux/zsh.nix` はその `zsh/.zshenv` / `zsh/.zshrc` を `home.file` で配布する
- `modules/home/programs/zsh.nix` は macOS の Home Manager 用設定として残す

### Linux bootstrap

Linux 初回セットアップは次の順で実行します。

1. `./scripts/linux/setup.sh`
2. Docker も必要なら `./scripts/linux/setup.sh --with-docker`
3. `home-manager switch --flake ./nix#kokiaoyagi`
4. `gcloud` を使うなら `gcloud init`

script ごとの責務と詳細は `scripts/README.md` を参照。

### `modules/linux/`

Linux 固有の責務を置く場所です。

#### `modules/linux/default.nix`

Linux 用 Home Manager wrapper です。

- `home.username`
- `home.homeDirectory`
- `modules/home/default.nix` の import

#### `modules/linux/packages.nix`

Linux だけに必要な package や import を置きます。

Linux 固有差分を `modules/home/` の条件分岐で増やしすぎないこと。
`mo` はまだ Linux には入れない。必要になったら `k1LoW/mo` 用 package を overlay に追加し、nixpkgs の別物 `mo` と衝突しない attr 名でここへ入れる。

## Common Tasks

| Task | Write Here |
| --- | --- |
| 共通 package を追加 | `modules/home/packages.nix` |
| macOS 専用 package を追加 | `modules/darwin/packages.nix` |
| Homebrew package を追加 | `modules/darwin/homebrew.nix` |
| git 設定を変える | `modules/home/programs/git.nix` |
| gh 設定を変える | `modules/home/programs/gh.nix` |
| Codex の keymap / config を変える | `modules/home/programs/codex/config.nix` |
| AGENTS.md / CLAUDE.md(グローバル指示)を変える | agent-kit repo + `.apm/apm.yml` |
| agent skills を追加/削除する | agent-kit repo + `.apm/apm.yml` |
| external skill collection を変える | `modules/home/programs/agent-skills/external/` |
| Codex の macOS install を変える | `modules/darwin/homebrew.nix` |
| mise の global runtime を変える | `modules/home/programs/mise.nix` |
| macOS の zsh 設定を変える | `modules/home/programs/zsh.nix` |
| Linux の zsh 設定を変える | repo root `zsh/` と `modules/linux/zsh.nix` |
| tmux 設定を変える | `modules/home/programs/tmux.nix` |
| Neovim module 側を変える | `modules/home/programs/nvim.nix` |
| Neovim の Lua / asset を変える | `modules/home/assets/nvim/` |
| macOS system 設定を変える | `modules/darwin/system.nix` |
| darwin と Home Manager の橋渡しを変える | `modules/darwin/home-manager.nix` |
| overlay を追加する | `overlays/` |
| flake entry を増やす / 配線を変える | `flake.nix` |

## Rules

### Rule 1

新しい設定は `nix/home-manager/` や `nix/nix-darwin/` の直下へ増やさないこと。

新規追加先は原則として以下です。

- `modules/home/`
- `modules/darwin/`
- `modules/linux/`
- `overlays/`
- `lib/`

### Rule 2

`flake.nix` は入口の配線だけを担当すること。

- package 群を直書きしない
- program 設定を書かない
- user 設定本体を書かない

### Rule 3

共通設定に OS 条件分岐を増やしすぎないこと。

判断基準:

- 共通なら `modules/home/`
- macOS 固有なら `modules/darwin/`
- Linux 固有なら `modules/linux/`

### Rule 4

asset と module を分けること。

- Nix module: `programs/*.nix`
- 実ファイル: `assets/<tool>/`

### Rule 5

1 file 1 responsibility を崩さないこと。

例:

- `git` 設定は `git.nix`
- `gh` 設定は `gh.nix`
- Homebrew 一覧は `homebrew.nix`

## Important

- `nix/README.md` を `nix/` 配下の責務整理の SoT とする
- 構成判断に迷ったら、まず README を更新してからコードを動かす
- README に反する置き方は、一時的でも増やさない
