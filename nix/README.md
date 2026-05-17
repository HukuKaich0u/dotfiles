# Nix Configuration SoT

この README は `nix/` 配下の **source of truth** です。

- いま実際にどう置かれているか、ではなく
- これから **どの構成に寄せるか**
- どこに何を書くべきか

を定義します。

今後 `nix/` 配下を触るときは、まずこの README に従います。

## Goal

- macOS は `nix-darwin` を入口に使う
- Linux は standalone `home-manager` を入口に使う
- 共通の user 設定は `modules/home/` に寄せる
- OS 固有差分は `modules/darwin/` と `modules/linux/` に閉じ込める
- overlay と helper は `overlays/` と `lib/` に分ける
- `flake.nix` は入口の配線だけを担当し、設定本体を持たない

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
    │   │   ├── bacon.nix
    │   │   ├── gh.nix
    │   │   ├── git.nix
    │   │   ├── mise.nix
    │   │   ├── nvim.nix
    │   │   ├── starship.nix
    │   │   ├── tmux.nix
    │   │   ├── wezterm.nix
    │   │   ├── yazi.nix
    │   │   └── zsh.nix
    │   └── assets/
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
        └── packages.nix
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

- `git`
- `ripgrep`
- `fd`
- `gnumake`
- `tmux`
- `lazygit`
- `imagemagick`

package 一覧を `default.nix` に直接肥大化させないこと。

#### `modules/home/programs/`

各ツールごとの Home Manager module を置きます。

- 1 program = 1 file
- `programs.<name>` の設定はここ
- 特定ツールの `xdg.configFile` もここ

例:

- `git.nix`
- `gh.nix`
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
- WezTerm の Lua config

Lua や tmux conf のような asset を `programs/` と同じ階層に散らさないこと。

#### `modules/home/programs/codex.nix`

Codex の Home Manager 側の接着層です。

- `~/.codex/config.toml` を Nix から生成する
- `~/.codex/AGENTS.md` を repo root の `/.codex/AGENTS.md` へ向ける
- Codex 本体の install はここで持たない

ここには Home Manager で配るための配線だけを書き、Codex 本体の install 経路は別の module で管理します。

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

現状の Codex install もここで管理します。

- `codex` の install は Homebrew cask
- Codex の設定ファイル配布は `modules/home/programs/codex.nix`

Nix package で足りるものはまず Nix を優先し、Homebrew は macOS 依存や運用上必要なものだけに寄せます。

## Codex Layout

Codex まわりは install / config / prompt assets を分けて考えます。

### install

- macOS: `modules/darwin/homebrew.nix`
- Linux: まだ未定

### config

- `modules/home/programs/codex.nix`
- `~/.codex/config.toml` を Home Manager で生成

現状 `config.toml` に入れている設定はこれです。

```toml
[tui.keymap.global]
open_external_editor = []
```

これはプロンプト入力中に external editor を開く操作を無効化する設定です。

### prompt assets

- repo root `/.codex/AGENTS.md`
- repo root `/.agents/skills/`

役割はこう分けます。

- `/.codex/`
  - Codex がそのまま読む repo 側の置き場
  - 今は `AGENTS.md` だけ
- `/.agents/`
  - agent / skill 資産の SoT
  - `skills/` はここで管理

現状の `/.codex/AGENTS.md` は `/.agents/AGENTS.md` への symlink です。
つまり `AGENTS.md` の実体は `/.agents/AGENTS.md` にあります。

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

## Common Tasks

| Task | Write Here |
| --- | --- |
| 共通 package を追加 | `modules/home/packages.nix` |
| macOS 専用 package を追加 | `modules/darwin/packages.nix` |
| Homebrew package を追加 | `modules/darwin/homebrew.nix` |
| git 設定を変える | `modules/home/programs/git.nix` |
| gh 設定を変える | `modules/home/programs/gh.nix` |
| Codex の keymap / config を変える | `modules/home/programs/codex.nix` |
| Codex の AGENTS.md を変える | `../.agents/AGENTS.md` |
| Codex / agent skills を変える | `../.agents/skills/` |
| Codex の macOS install を変える | `modules/darwin/homebrew.nix` |
| mise の global runtime を変える | `modules/home/programs/mise.nix` |
| zsh 設定を変える | `modules/home/programs/zsh.nix` |
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

## Migration Policy

現時点では、実ファイルはまだこの構成へ完全には移っていません。

ただし、**今後のリファクタリングは必ずこの README を正とする** こと。

移行方針:

- `nix/home-manager/shared.nix`
  -> `modules/home/default.nix`
- `nix/home-manager/{bacon,gh,git,mise,nvim,starship,tmux,wezterm,yazi,zsh}.nix`
  -> `modules/home/programs/*.nix`
- `nix/home-manager/nvim/`
  -> `modules/home/assets/nvim/`
- `nix/home-manager/tmux/`
  -> `modules/home/assets/tmux/`
- `nix/home-manager/wezterm/`
  -> `modules/home/assets/wezterm/`
- `nix/home-manager/darwin.nix`
  -> `modules/darwin/default.nix`
- `nix/home-manager/linux.nix`
  -> `modules/linux/default.nix`
- `nix/nix-darwin/configuration.nix`
  -> `modules/darwin/system.nix`
- `nix/nix-darwin/home_manager.nix`
  -> `modules/darwin/home-manager.nix`
- `nix/nix-darwin/homebrew.nix`
  -> `modules/darwin/homebrew.nix`
- `nix/common/direnv-no-zsh-check-overlay.nix`
  -> `overlays/direnv-no-zsh-check.nix`
- `nix/common/nixpkgs.nix`
  -> `lib/` または `overlays/default.nix` / shared helper へ分解

## Important

- `nix/README.md` を `nix/` 配下の責務整理の SoT とする
- 構成判断に迷ったら、まず README を更新してからコードを動かす
- README に反する置き方は、一時的でも増やさない
