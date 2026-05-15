# Darwin Linux Home Manager Split 設計

**Goal:** `nix-darwin` を使う macOS と standalone `home-manager` を使う Linux を分離しつつ、日常のユーザー設定本体は共通 Home Manager モジュールとして再利用できる形に整理する。

## スコープ

含むもの:
- `nix/flake.nix` に macOS 用 `darwinConfigurations` と Linux 用 `homeConfigurations` の入口を並立させる
- `nix/home-manager/home.nix` の責務を見直し、共通設定本体を `shared` モジュールへ寄せる
- macOS 用 wrapper と Linux 用 wrapper を追加し、それぞれ `username` と `homeDirectory` を分離する
- `nix-darwin` 側の Home Manager 接続先を macOS wrapper へ付け替える

含まないもの:
- Linux 側に `nixosConfigurations` を追加すること
- package 群や shell 設定の大幅な見直し
- `flake-parts` や app runner の導入
- macOS / Linux 固有 package の最適化

## 参考にする構成

参考: `ryoppippi/dotfiles`

取り入れる点:
- OS ごとの entry point を `flake` で分ける
- Home Manager の実設定は cross-platform な共通モジュールに寄せる
- macOS 側だけを `nix-darwin` 配下に置く

取り入れない点:
- `flake-parts` ベースへの全面移行
- app / formatter / hook まわりの大きな拡張
- 1 つの `home.nix` に `pkgs.stdenv.isDarwin` 条件分岐を増やす構成

## 選択肢

### Option 1: 共通 Home Manager + OS 別 wrapper

`shared` に実設定本体を集め、`darwin` / `linux` は薄い入口だけを持つ。

Pros:
- 今の構成からの移行コストが小さい
- `username` と `homeDirectory` の差分を局所化できる
- 共通 module 群の二重管理を避けやすい

Cons:
- wrapper ファイルが増える

### Option 2: macOS 用 `home.nix` と Linux 用 `home.nix` を完全分離

Pros:
- OS ごとの入口が直感的

Cons:
- 共通 import と package が重複しやすい
- 今後の差分管理が重くなる

### Option 3: 1 つの Home Manager module に条件分岐を増やす

Pros:
- ファイル数は増えにくい

Cons:
- `if isDarwin then ... else ...` が散らばりやすい
- 責務分離が曖昧になる

## 推奨案

Option 1 を採用する。

この repo では、すでに `nix-darwin` と `home-manager` の入口が分かれ始めている。ここで共通設定本体を 1 か所へ寄せ、OS ごとの差分は wrapper に閉じ込めると、今後 Linux 用 package 差分や macOS 側の machine-level 設定を足しても境界が崩れにくい。

## 構成設計

### `nix/flake.nix`

責務:
- OS ごとの entry point を定義する
- macOS は `darwinConfigurations."KokiAoyagi"` を維持する
- Linux は standalone `home-manager` の `homeConfigurations."kokiaoyagi"` を追加する

設計:
- macOS 用 pkgs は引き続き `aarch64-darwin`
- Linux 用 pkgs は少なくとも 1 つの Linux system を明示する
- wrapper module の差し替え以外は既存 wiring を崩さない

### `nix/home-manager/shared.nix`

責務:
- 実際の user-facing Home Manager 設定本体を持つ

置くもの:
- 既存の `imports`
- 共通 `home.packages`
- `home.stateVersion`
- `home.sessionVariables`
- `programs.home-manager.enable`

置かないもの:
- `home.username`
- `home.homeDirectory`
- OS 固有の path 値

### `nix/home-manager/darwin.nix`

責務:
- macOS 用の Home Manager wrapper

置くもの:
- `imports = [ ./shared.nix ]`
- `home.username = "KokiAoyagi"`
- `home.homeDirectory = "/Users/KokiAoyagi"`

### `nix/home-manager/linux.nix`

責務:
- Linux 用の standalone Home Manager wrapper

置くもの:
- `imports = [ ./shared.nix ]`
- `home.username = "kokiaoyagi"`
- `home.homeDirectory = "/home/kokiaoyagi"`

### `nix/nix-darwin/home_manager.nix`

責務:
- `nix-darwin` から macOS wrapper を読む接続層

変更点:
- 接続先を `../home-manager/home.nix` から `../home-manager/darwin.nix` へ切り替える

## データフロー

macOS:
1. `flake.nix` が `darwinConfigurations."KokiAoyagi"` を公開する
2. `nix-darwin/configuration.nix` が `home_manager.nix` を import する
3. `home_manager.nix` が `home-manager.users."KokiAoyagi"` に macOS wrapper を渡す
4. macOS wrapper が `shared.nix` を import して共通設定を再利用する

Linux:
1. `flake.nix` が `homeConfigurations."kokiaoyagi"` を公開する
2. Linux wrapper が `shared.nix` を import する
3. standalone `home-manager` が Linux 用の username / homedir で評価される

## テスト方針

- 既存の shape test があれば、entry point と import 先の更新に合わせて修正する
- `nix eval` で macOS と Linux の両 entry が評価できることを確認する
- 可能なら `home-manager build --flake` 相当で Linux wrapper の activation package を確認する
- macOS 側は `darwin-rebuild switch` までは行わず、評価または build に留める

## リスク

- Linux の target system を先に 1 つしか決めないと、将来 `aarch64-linux` を足すときに入口追加が必要になる
- 共通 package の一部が Linux で未対応だと、分離直後に評価エラーになる可能性がある
- `home.homeDirectory` を wrapper に逃がしても、各 module 内に macOS 前提 path が残っていると Linux 側で詰まる

## 成功条件

- macOS は引き続き `nix-darwin` 経由で Home Manager を読める
- Linux は standalone `home-manager` entry から同じ共通設定本体を読める
- `username` と `homeDirectory` の OS 差分が wrapper に閉じる
- 今後の共通設定追加時に、OS ごとの複製編集が不要になる
