# Home Manager CLI Migration 設計

**Goal:** この dotfiles でまだ symlink / Homebrew 主体になっている `bacon` `wezterm` `nvim` を、責務に応じて Home Manager へ移し、設定の source of truth を `.config/nix/home-manager` 配下へ寄せる。

## スコープ

含むもの:
- `bacon` の本体導入と設定管理を Home Manager 化する
- `wezterm` の設定ファイル管理を Home Manager 化する
- `nvim` の本体導入と設定ファイル管理を Home Manager 化する
- `install.sh` の symlink 配布対象から `bacon` `wezterm` `nvim` を外す
- 既存移行と同じ形の shell regression test を追加する

含まないもの:
- `wezterm` 本体の Homebrew cask 管理をやめること
- `nvim` の language server / formatter / Mason 周辺を全面的に Nix 管理へ置き換えること
- `bacon` `wezterm` `nvim` の挙動見直しや新機能追加
- 既存 `brew` package/cask 一覧の大整理

## 前提

- 既存 Home Manager 管理は `git` `gh` `mise` `starship` `tmux` `yazi` `zsh`
- `install.sh` は `.config` 配下を包括的に symlink するが、一部は `SKIP_CONFIG_DIRS` で除外済み
- 現在の未移行対象は少なくとも `.config/bacon/prefs.toml` `.config/wezterm/*` `.config/nvim/*`

## 選択肢

### Option 1: `bacon` は Home Manager option、`wezterm` は config のみ、`nvim` は本体+config を Home Manager 化

`bacon` は `programs.bacon.settings` を優先して Nix attrset で再現する。`wezterm` は本体を Homebrew cask に残し、設定だけ `xdg.configFile` で配布する。`nvim` は `programs.neovim.enable = true` と設定ディレクトリ管理を Home Manager に移す。

Pros:
- 各ツールの実態に合わせた責務分離になる
- `wezterm` の cask 事情を崩さずに設定だけ移せる
- CLI 系は Home Manager に寄せられる
- 現在の repo 構成に最も自然に乗る

Cons:
- `wezterm` だけ本体と config の管理主体が分かれる
- `nvim` は本体だけ Nix 化しても外部依存が一部残る

### Option 2: 3 つとも設定だけ先に Home Manager 化し、本体は後回し

Pros:
- 初回の移行差分が小さい
- 実行時依存の切り分けが後回しで済む

Cons:
- `bacon` と `nvim` の Home Manager 化としては中途半端
- package 管理の source of truth が分散し続ける

### Option 3: `bacon` か `nvim` のみ先行し、`wezterm` は現状維持

Pros:
- 影響範囲が最小

Cons:
- 今回の「少しずつ移行する」流れに対して進みが遅い
- `install.sh` と Home Manager の責務分離が途切れる

## 推奨案

Option 1 を採用する。

`wezterm` は GUI app であり、現状は cask 管理のままにしておくのが最も実務的である。一方 `bacon` と `nvim` は CLI / editor として Home Manager に寄せやすい。これにより、設定ファイルの source of truth は `.config/nix/home-manager` に集約しつつ、パッケージ管理は無理のない境界で分担できる。

## 構成設計

### `home.nix`

- `.config/nix/home-manager/home.nix` に以下を追加する
  - `./bacon.nix`
  - `./wezterm.nix`
  - `./neovim.nix`

### `bacon.nix`

新規に `.config/nix/home-manager/bacon.nix` を追加する。

責務:
- `programs.bacon.enable = true`
- 可能な限り `programs.bacon.settings` で現在の `prefs.toml` を再現する
- 今回の設定は少量なので、まずは file 配布ではなく option で完結させる

設定方針:
- `listen = true`
- `[exports.locations]` 以下の `auto`, `path`, `line_format` を attrset へ変換する

フォールバック:
- もし Home Manager module が `prefs.toml` の shape を表現できない場合のみ `xdg.configFile` に切り替える
- ただし初回実装は option 完結を優先する

### `wezterm.nix`

新規に `.config/nix/home-manager/wezterm.nix` を追加する。

責務:
- `wezterm` の config file 配布
- `wezterm.lua` と `keybinds.lua` を Home Manager 管理へ移す

管理境界:
- `wezterm` app 本体は `homebrew.nix` 側の cask 管理を維持する
- Home Manager 側では package 導入はしない

配布方式:
- `xdg.configFile."wezterm/wezterm.lua".source = ./wezterm/wezterm.lua`
- `xdg.configFile."wezterm/keybinds.lua".source = ./wezterm/keybinds.lua`

### `neovim.nix`

新規に `.config/nix/home-manager/neovim.nix` を追加する。

責務:
- `programs.neovim.enable = true`
- `~/.config/nvim` の source of truth を Home Manager 側へ移す
- 初回は editor 本体と設定所有権の移管までを担当する

配布方式:
- `xdg.configFile."nvim".source = ./nvim`

依存方針:
- 初回移行では `nvim` 本体導入を優先する
- `mason` や各種 language server を全面 Nix 化するのは別テーマに切り出す
- 必要があれば `home.packages` / `programs.neovim.extraPackages` で最低限の CLI だけ補うが、ここでは過剰に広げない

## ファイル配置

新しい source of truth は次のように置く。

- `.config/nix/home-manager/bacon.nix`
- `.config/nix/home-manager/wezterm.nix`
- `.config/nix/home-manager/wezterm/wezterm.lua`
- `.config/nix/home-manager/wezterm/keybinds.lua`
- `.config/nix/home-manager/neovim.nix`
- `.config/nix/home-manager/nvim/` 以下に既存 Neovim 設定一式

これに伴い、旧配置の `.config/bacon` `.config/wezterm` `.config/nvim` は symlink 管理の source から外す。

## データフロー

### bacon

1. Home Manager が `programs.bacon.settings` から `prefs.toml` を生成する
2. `bacon` 実行時は生成された設定を読む
3. `install.sh` は `bacon` 配下に関与しない

### wezterm

1. Home Manager が `~/.config/wezterm/*` を配置する
2. Homebrew cask の `wezterm` app がその設定を読む
3. `install.sh` は `wezterm` 配下に関与しない

### neovim

1. Home Manager が `nvim` package と `~/.config/nvim` を管理する
2. `nvim` 起動時は Home Manager 配下の設定を読む
3. `install.sh` は `nvim` 配下に関与しない

## エラーハンドリング / 衝突対策

### 既存 symlink との衝突

既存環境では `~/.config/bacon` `~/.config/wezterm` `~/.config/nvim` が repo 直リンクになっている可能性がある。

今回の実装で行うこと:
- `install.sh` の `SKIP_CONFIG_DIRS` に `bacon` `wezterm` `nvim` を追加する
- 以後の再リンクを防ぐ

初回適用時の確認事項:
- 既存 symlink が残っている場合、`home-manager switch` 時に衝突しないか
- 必要なら一度 unlink/backup してから switch する

### 挙動差分の抑制

- `bacon` は既存 `prefs.toml` と同値の設定だけを移す
- `wezterm` は Lua ファイルをそのまま移し、内容自体は変えない
- `nvim` も初回は設定内容を極力変えず、配置と所有権だけを移す

## テスト方針

各ツールに対して既存移行と同型の shell regression test を追加する。

### `bacon`

- `home.nix` が `./bacon.nix` を import している
- `bacon.nix` が `programs.bacon` を定義している
- 期待する settings key が存在する
- `install.sh` が `bacon` を skip する
- 旧 `.config/bacon/prefs.toml` が source of truth でなくなる

### `wezterm`

- `home.nix` が `./wezterm.nix` を import している
- `wezterm.nix` が `xdg.configFile` を定義している
- `wezterm.lua` `keybinds.lua` が Home Manager 配下へ移されている
- `install.sh` が `wezterm` を skip する
- `homebrew.nix` が `wezterm` cask を保持していることを必要に応じて確認する

### `nvim`

- `home.nix` が `./neovim.nix` を import している
- `neovim.nix` が `programs.neovim.enable = true;` を含む
- `xdg.configFile."nvim"` か同等の配線が存在する
- `install.sh` が `nvim` を skip する
- 旧 `.config/nvim` が symlink 管理の source でなくなる

### 共通検証

- `home-manager build --flake .config/nix#KokiAoyagi` が通る
- `result/home-files/.config` に `wezterm` `nvim` と必要な `bacon` 設定が生成される
- 生成結果が既存設定内容と整合する

## 実装順

1. `bacon` 移行
2. `wezterm` 設定移行
3. `nvim` 移行

この順番にする理由:
- `bacon` が最も小さく、option だけで閉じやすい
- `wezterm` は本体管理を触らず config だけ移すため中規模
- `nvim` は設定量が最も多く、最後に切り出すのが安全

## リスク

- `bacon` module option が現在の `prefs.toml` shape を完全に再現できない可能性
- `wezterm` cask が将来別経路に変わると、本体/設定の分担見直しが必要
- `nvim` は外部 CLI や plugin 前提が多く、本体だけ移しても実行環境差分が残る可能性
- 既存 symlink が残ったままだと初回 switch 時に衝突する可能性

## 成功条件

- `bacon` の本体と設定が Home Manager 管理になる
- `wezterm` は app 本体を Homebrew に残したまま config が Home Manager 管理になる
- `nvim` は本体と config の所有権が Home Manager へ移る
- `install.sh` は `bacon` `wezterm` `nvim` を再リンクしない
- 既存の挙動差分が最小限に抑えられる
