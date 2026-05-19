# Zoxide Cross-Platform Design

## Goal

- `zoxide` を Nix 管理に追加する
- macOS と Linux の両方で `zoxide` コマンドと zsh 連携を使えるようにする
- 既存の責務分離を崩さず、`programs/*` に寄せる

## In Scope

- Home Manager 共通 module への `zoxide` 追加
- macOS の Home Manager zsh 統合
- Linux の repo 配布 `.zshrc` への `zoxide` 初期化追加
- 既存 migration test への確認追加

## Approved Design

### Common Module

- 新規 [nix/modules/home/programs/zoxide.nix](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/nix/modules/home/programs/zoxide.nix) を追加する
- [nix/modules/home/default.nix](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/nix/modules/home/default.nix) から import する
- module では少なくとも次を管理する

```nix
programs.zoxide = {
  enable = true;
  enableZshIntegration = true;
};
```

`programs.zoxide.enable` により package 導入は Home Manager 側へ寄せる。`enableZshIntegration` も明示し、将来の既定値変更に依存しない。

### macOS Behavior

- macOS は既存どおり [nix/modules/home/programs/zsh.nix](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/nix/modules/home/programs/zsh.nix) で `programs.zsh` を有効化している
- このため Home Manager の `programs.zoxide` module が `programs.zsh.initContent` に統合コードを差し込める
- macOS 側の `zsh.nix` には `zoxide` 用の直書きを追加しない

### Linux Behavior

- Linux は `programs.zsh.enable` を前提にせず、repo 直下の `zsh/.zshrc` を配布している
- そのため Home Manager の `enableZshIntegration` だけでは Linux の interactive zsh に初期化が入らない
- Linux 側は [zsh/.zshrc](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/zsh/.zshrc) に `eval "$(zoxide init zsh)"` を追加して揃える
- package 自体は共通 module 側が導入するので、Linux 側のテンプレートは初期化だけを持つ

## Data Flow

1. Home Manager が `zoxide` package を導入する
2. macOS では `programs.zsh.initContent` に `zoxide init zsh` が自動注入される
3. Linux では配布済み `.zshrc` が `zoxide init zsh` を評価する
4. 結果として両 OS で `z`, `zi` などの zoxide 操作が同じ入口で使える

## Constraints

- Linux の shell 配布方式は維持する
- `zoxide` 用に OS 別 package 定義を増やさない
- `zoxide` 初期化は interactive shell に限定する
- 既存の `mise`、`starship`、補完初期化の順序を壊さない

## Error Handling

- Linux で `.zshrc` から `zoxide init zsh` を呼ぶ前提なので、package 導入と初期化追加は同じ変更セットで入れる
- macOS 側では Home Manager module に任せ、手書き init 行との二重初期化を避ける

## Testing Impact

- [tests/zsh_nix_migration_test.sh](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/tests/zsh_nix_migration_test.sh) に次を追加する
- `modules/home/default.nix` が `./programs/zoxide.nix` を import していること
- `nix/modules/home/programs/zoxide.nix` が存在し、`nix-instantiate --parse` を通ること
- `zoxide.nix` が `programs.zoxide.enable = true` と `enableZshIntegration = true` を持つこと
- `zsh/.zshrc` が `eval "$(zoxide init zsh)"` を持つこと

## Out of Scope

- bash, fish, nushell 向け integration 追加
- `zoxide` の alias や `--cmd` カスタマイズ
- Linux 側を `programs.zsh.enable` ベースへ移行する作業
