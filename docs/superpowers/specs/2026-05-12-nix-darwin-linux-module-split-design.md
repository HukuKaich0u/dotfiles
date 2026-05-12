# Nix Darwin/Linux Module Split Design

**Goal:** `nix-darwin` を macOS の system entrypoint として残しつつ、Linux では standalone `home-manager` を使う形に再編し、共通設定を `nix/modules/home` へ寄せる。

## Scope

この段階の目的は、参考にしている `ryoppippi/dotfiles` のように入口を platform ごとに分けることです。

- macOS: `darwinConfigurations."KokiAoyagi"` を `aarch64-darwin` で維持する
- Linux: `homeConfigurations."kokiaoyagi"` を `aarch64-linux` で追加する
- 共通 Home Manager 設定を `nix/modules/home` に移す
- mac 固有の machine-level 設定を `nix/modules/darwin/system.nix` に寄せる
- 第1段階では Linux 向けの機能拡張よりも、Linux で evaluation / build が通る構造を優先する

この段階では NixOS 対応、`darwin-rebuild switch` の適用、asset tree の全面移動までは扱いません。

## Target Structure

### `nix/flake.nix`

`flake.nix` は entrypoint map と package set builder に責務を絞る。

- `mkPkgs system` を持つ
- `darwinConfigurations."KokiAoyagi"` を定義する
- `homeConfigurations."kokiaoyagi"` を定義する
- 共通の nixpkgs tweak は `nix/common/nixpkgs.nix` を通して使う

`homeConfigurations` は standalone Home Manager のままにし、Linux では system-level module を持ち込まない。

### `nix/modules/home/default.nix`

共通 Home Manager の root module とする。

- `home.username`
- `home.homeDirectory`
- `home.stateVersion`
- 共通 package
- 共通 programs import
- `programs.home-manager.enable`

import 先は `nix/modules/home/programs/` に揃える。

### `nix/modules/home/programs/*.nix`

既存の `nix/home-manager/*.nix` を責務ごとに移す。

- `git.nix`
- `gh.nix`
- `mise.nix`
- `nvim.nix`
- `starship.nix`
- `tmux.nix`
- `wezterm.nix`
- `yazi.nix`
- `zsh.nix`
- `bacon.nix`

第1段階では `nvim/`, `tmux/`, `wezterm/` の asset tree 自体は移動せず、新しい module から既存 path を参照する。

### `nix/modules/darwin/system.nix`

`nix-darwin` 側の machine-level 設定を置く。

- `system.stateVersion`
- `system.configurationRevision`
- `system.primaryUser`
- `users.users.<name>.home`
- `imports` による darwin module wiring

Homebrew list は別ファイルに分ける。

### `nix/modules/darwin/default.nix`

Home Manager 側に注入する macOS user-level 差分を置く。

- darwin 専用 package
- 将来的な darwin 専用 user config

第1段階では最小限として、共通 package に置けない `pngpaste`, `ascii-image-converter` などをこちらで持つ。

### `nix/modules/darwin/homebrew.nix`

既存の Homebrew taps / brews / casks をここへ維持する。

### `nix/modules/linux/default.nix`

Linux user-level 差分の受け皿にする。

第1段階では最小構成でよく、必要なのは「共通 module だけでは吸収しきれない Linux 差分」を置く場所としての境界です。

## Platform Strategy

### Common modules must stay Linux-safe

`nix/modules/home/default.nix` と `nix/modules/home/programs/*.nix` には、両 OS で評価できるものだけを置く。

- 共通 package に残す候補
  - `git`
  - `ripgrep`
  - `fd`
  - `gnumake`
  - `tmux`
  - `lazygit`
  - `imagemagick`
- mac 専用に寄せる候補
  - `pngpaste`
  - `ascii-image-converter`

### Shared program modules

- `tmux.nix` は runtime で `Darwin` / それ以外を分岐しているため共通に残せる
- `nvim.nix` は clipboard/image helper が runtime で executable の有無を確認するため共通に残せる
- `zsh.nix` は `/opt/homebrew` や `$HOME/Library/pnpm` を存在確認してから使っているため、第1段階では共通に残せる

ただし `zsh.nix` の darwin 寄り PATH ブロックは、将来的には `darwin/default.nix` から差し込める形に整理する余地がある。

## Migration Plan

### Move now

- `nix/home-manager/home.nix` の責務を `nix/modules/home/default.nix` に移す
- `nix/home-manager/{git,gh,mise,nvim,starship,tmux,wezterm,yazi,zsh,bacon}.nix` を `nix/modules/home/programs/` へ移す
- `nix/nix-darwin/configuration.nix` / `homebrew.nix` 相当を `nix/modules/darwin/` へ移す
- `nix/flake.nix` を `mkPkgs` + `darwinConfigurations` + `homeConfigurations.kokiaoyagi` 構成へ変える

### Leave in place for phase 1

- `nix/home-manager/nvim/**`
- `nix/home-manager/tmux/tmux.conf`
- `nix/home-manager/wezterm/**`

理由は、asset tree の移動まで同時にやると「責務の再編」と「参照先の再配線」が混ざり、差分の意味が読みづらくなるためです。

## Verification

### Text regressions

既存テストのうち、旧 path を直接見ているものを新 path 前提に更新する。

特に確認対象:

- `tests/home_manager_only_flake_test.sh`
- `tests/nix_darwin_reset_test.sh`
- `tests/ghconfig_paths_test.sh`
- `tests/tmux_nix_migration_test.sh`
- `tests/bacon_home_manager_migration_test.sh`
- `tests/yazi_home_manager_migration_test.sh`
- `tests/nvim_home_manager_migration_test.sh`
- `tests/zsh_nix_migration_test.sh`
- `tests/mise_home_manager_bootstrap_test.sh`
- `tests/wezterm_home_manager_migration_test.sh`
- `tests/gitconfig_paths_test.sh`

### Nix evaluation

- macOS: `nix eval ./nix#darwinConfigurations.KokiAoyagi.system.primaryUser --raw`
- Linux: `nix eval ./nix#homeConfigurations.kokiaoyagi.config.home.username --raw`

### Build

- Linux: `home-manager build --flake ./nix#kokiaoyagi`

第1段階では macOS 側は evaluation 維持までを必須とし、`darwin-rebuild switch` 実行までは要求しない。

## Success Criteria

- `nix/flake.nix` の正規入口が `nix/modules/**` を参照する
- `darwinConfigurations."KokiAoyagi"` が引き続き評価できる
- `homeConfigurations."kokiaoyagi"` が `aarch64-linux` で評価できる
- Linux で standalone `home-manager build --flake ./nix#kokiaoyagi` が通る
- 共通 module root に mac 専用 package が漏れず、platform 差分の境界が明確になる
