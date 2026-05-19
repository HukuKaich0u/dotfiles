# Linux Tool Ownership Design

## Goal

- ここまで議論した個別ツールだけについて、Darwin と Ubuntu の管理先を明文化する
- 全体的な package 戦略の再整理までは扱わない

## In Scope

- `google-cloud-sdk`
- `awscli` / `awscli2`
- `codex`
- `bun`
- `lua`
- `terraform`
- `zsh`
- `wezterm`

## Approved Ownership

### google-cloud-sdk

- macOS: Homebrew
- Ubuntu: `apt`

`google-cloud-sdk` は両 OS ともベンダー SDK として扱い、Nix には寄せない。

### awscli / awscli2

- macOS: Homebrew で `awscli`
- Ubuntu: Home Manager で `awscli2`

macOS 側は既存の Homebrew 管理を維持する。Ubuntu 側は共通 CLI として Home Manager 管理に寄せる。

### codex

- macOS: Homebrew
- Ubuntu: `mise` で入れた Node 24 上の `npm -g`

`codex` は両 OS で管理先を揃えない。macOS は既存運用を維持し、Ubuntu だけ npm global 管理にする。

### bun

- macOS: `mise`
- Ubuntu: `mise`

### lua

- macOS: `mise`
- Ubuntu: `mise`

### terraform

- macOS: `mise`
- Ubuntu: `mise`

`bun`、`lua`、`terraform` は言語/runtime/開発ツールとして扱い、両 OS で `mise` に寄せる。

### zsh

- macOS: 現状の Darwin 側運用を維持する
- Ubuntu: `apt`

Ubuntu では `zsh` 本体を `apt` で入れる。`programs.zsh.enable` を使って login shell まで Home Manager 側で面倒を見る構成にはしない。

このため、Ubuntu 対応では少なくとも次を守る。

- Ubuntu は `programs.zsh.enable` 前提にしない
- Ubuntu の login shell 変更はこの設計の責務外とする
- Ubuntu でも必要なら zsh 設定ファイル配布だけは別責務で扱えるようにする

### wezterm

- macOS: 既存どおり Homebrew
- Ubuntu: 管理しない

Ubuntu では `wezterm` を package 管理対象に含めない。

## Linux Setup Order

Ubuntu 側で今回の対象ツールを揃える順序は次とする。

1. `apt` で `zsh` と `google-cloud-sdk` を導入する
2. Home Manager で `awscli2` を導入する
3. `mise` で `node@24`、`bun`、`lua`、`terraform` を導入する
4. `codex` を npm global で導入する

## Constraints

- macOS 側の `codex` は Homebrew 管理のまま変えない
- Ubuntu では `wezterm` を追加しない
- 言語と runtime は `mise` に寄せる
- `google-cloud-sdk` は Nix に寄せない

## Testing Impact

- Darwin 側では `google-cloud-sdk`、`awscli`、`codex`、`wezterm` が引き続き Homebrew 管理であることを確認する
- Ubuntu 側では `google-cloud-sdk` が `apt`、`awscli2` が Home Manager、`codex` が npm global、`bun`/`lua`/`terraform` が `mise` という責務を確認する
- `zsh` について、Ubuntu では `programs.zsh.enable` を前提にしない実装であることを確認する

## Out of Scope

- 共通 CLI 全体の再棚卸し
- Homebrew にある他の CLI の移管判断
- Ubuntu の GUI アプリ戦略
- `codex` npm 導入の細かい bootstrap 手順
