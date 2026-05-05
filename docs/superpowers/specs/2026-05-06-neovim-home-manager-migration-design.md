# Neovim Home Manager Migration 設計

**Goal:** `nvim` の本体導入と設定配布責務を `home-manager` へ移し、既存の大規模 Lua 設定はそのまま維持しつつ、`install.sh` ベースの symlink 管理から切り離す。

## スコープ

含むもの:
- `programs.neovim` による `nvim` 本体管理
- 既存 `.config/nvim` の runtime source of truth を `nix/home-manager` 配下へ移す
- `xdg.configFile."nvim"` による既存設定ディレクトリの配布
- `mason` 管理外の基盤依存と外部コマンドの棚卸し
- `install.sh` の symlink 管理対象から `nvim` を外すための整理
- 移行用 regression test の追加

含まないもの:
- `mason` 管理下の LSP / formatter を全面的に Nix 管理へ置き換えること
- Lua 設定の大規模整理や plugin 構成変更
- `rustowl` の Nix 移行
- `image.nvim` と `luarocks` ベース画像表示の Nix 移行
- Homebrew 管理中の他 CLI の整理

## 現状整理

- `home.nix` には `git` `gh` `mise` `starship` `tmux` `wezterm` `yazi` `zsh` が import 済み
- `nvim` だけが引き続き `.config/nvim` の repo 直管理に残っている
- plugin 管理は `lazy.nvim`、LSP / formatter の配布は主に `mason.nvim` と `mason-tool-installer.nvim`
- ただし `nvim` は `mason` 管理外のコマンドにも依存している

## 選択肢

### Option 1: `nvim` 本体と設定配布だけを Home Manager 化し、依存は後回し

Pros:
- 初回差分が小さい
- 既存 Lua 設定にほぼ触れずに済む

Cons:
- `rg` `make` `lazygit` などが抜けると移行後に普通に壊れる
- 「移行したが使えない」状態になりやすい

### Option 2: `mason` は維持しつつ、`mason` 管理外の依存だけ先に Home Manager へ寄せる

Pros:
- 今回の目的を `Home Manager への責務移管` に限定できる
- `mason` 前提の現行構成を崩さずに前進できる
- 起動不能や主要機能破損のリスクを下げられる

Cons:
- 一時的に依存管理主体が `home-manager` と `mason` に分かれる
- 境界を文書化しないと後で混乱しやすい

### Option 3: LSP / formatter まで含めて全部 Nix 化する

Pros:
- 依存の source of truth が一本化される
- 最終形としては最も宣言的

Cons:
- 今回の作業が「Home Manager 移行」ではなく「Neovim 配布方式の全面刷新」になる
- `mason.lua` `lspconfig.lua` 周りの設計変更が大きい
- 破壊範囲が広い

## 推奨案

Option 2 を採用する。

今回は `nvim` の Home Manager 移行が目的であり、`mason` を捨てることは目的ではない。現状の設定は `mason` による LSP / formatter 配布を前提にかなり組まれているため、そこまで同時に置き換えると作業の主題が変わる。したがって初回は、`home-manager` が editor 本体、設定配布、`mason` 管理外の外部依存だけを持ち、LSP / formatter の配布は `mason` に残すのが最も実務的である。

## 責務境界

### Home Manager が持つもの

- `programs.neovim.enable = true`
- `xdg.configFile."nvim"` による既存設定ディレクトリ配布
- `lazy.nvim` 初回 bootstrap に必要な `git`
- picker / grep / build / terminal integration に必要な `mason` 管理外コマンド

### Mason が持つもの

- `mason-lspconfig` の `ensure_installed` にある LSP server 群
- `mason-tool-installer` の `ensure_installed` にある formatter / linter 群
- `lspconfig.lua` が前提にしている `lua_ls` `ts_ls` `clangd` `pyright` `ruff` などの配布

### 初回移行で明示的に除外するもの

- `rustowl`
  - 現状は plugin build が `cargo binstall rustowl --no-confirm` 前提
  - `mason` 管理でも Home Manager 管理でもないため、後続フェーズで別途扱う
- `image.nvim`
  - 現状は `imagemagick` に加えて `~/.luarocks` の `magick` rock 前提
  - 初回移行では無効化または未対応として扱い、後続フェーズで整理する

## 依存棚卸し

### Phase 1 で Home Manager に寄せる依存

基盤依存:
- `neovim`
- `git`
- `ripgrep`
- `fd`
- `make`
- `tmux`

機能依存:
- `lazygit`
- `imagemagick`
- `pngpaste`
- `ascii-image-converter`

条件付き依存:
- `kitty`
  - `image.nvim` を除外するため初回は必須ではない
  - 将来画像表示を戻す時に再評価する

### Phase 1 では Mason に残す依存

- `lua_ls`
- `ts_ls`
- `html`
- `cssls`
- `tailwindcss`
- `astro`
- `svelte`
- `emmet_language_server`
- `eslint`
- `typos_lsp`
- `gopls`
- `pyright`
- `ruff`
- `clangd`
- `zls`
- `nil_ls`
- `bashls`
- `biome`
- `prettier`
- `stylua`
- `gofumpt`
- `clang-format`
- `alejandra`
- `shfmt`
- `shellcheck`

## 構成設計

### `nix/home-manager/home.nix`

- `./nvim.nix` を import に追加する
- 既存 module 群と同列で管理する

### `nix/home-manager/nvim.nix`

新規に追加する。

責務:
- `programs.neovim.enable = true`
- 必要に応じて default editor / alias / vi/vim alias をこの module でまとめる
- `home.packages` に `mason` 管理外依存を列挙する
- `xdg.configFile."nvim"` で設定ディレクトリを配布する

### `nix/home-manager/nvim/`

- 既存 `.config/nvim` 一式を移す
- Lua 設定内容自体は初回では極力変えない
- ただし `rustowl` と `image.nvim` だけは初回移行方針に合わせて明示的に無効化する

## ファイル配置

移行後の source of truth:

- `nix/home-manager/nvim.nix`
- `nix/home-manager/nvim/` 以下に既存 Neovim 設定一式

役割変更:

- 旧 `.config/nvim` は runtime source ではなくなる
- `install.sh` は `nvim` を `~/.config` に symlink しない

## データフロー

1. Home Manager が `nvim` package と `~/.config/nvim` を生成・配布する
2. `nvim` 起動時は Home Manager 配下の設定を読む
3. `lazy.nvim` が必要 plugin を管理する
4. `mason` が LSP / formatter を引き続き配布する
5. `install.sh` は `nvim` 配下に関与しない

## エラーハンドリング / 衝突対策

### 既存 symlink との衝突

既存環境では `~/.config/nvim` が repo 直リンクの可能性がある。

今回の実装で行うこと:
- `install.sh` の `SKIP_CONFIG_DIRS` に `nvim` を追加する
- 今後の再リンクを止める

初回適用時の確認事項:
- `~/.config/nvim` が既存 symlink のまま残っていないか
- `home-manager switch` 前に unlink / backup が必要か

### 挙動差分の抑制

- Lua 設定の構造や plugin 採用は基本的に変えない
- 変更は `source of truth` と依存導入経路の整理に限定する
- `rustowl` / `image.nvim` は初回で動かないことを意図的に受け入れる代わりに、除外を明文化する

## テスト方針

### 静的テスト

- `home.nix` が `./nvim.nix` を import している
- `nvim.nix` が `programs.neovim` を定義している
- `xdg.configFile."nvim"` または同等配線が存在する
- `nvim.nix` に `mason` 管理外依存が入っている
- `install.sh` が `nvim` を skip する

### build / 生成確認

- `home-manager build --flake ./nix#KokiAoyagi` が通る
- build 生成物に `~/.config/nvim` 相当が含まれる
- `nvim` 実行に必要な `git` `rg` `fd` `make` `tmux` `lazygit` `magick` `pngpaste` `ascii-image-converter` が PATH 上に出る

### 動作確認

- `nvim` が起動する
- `lazy.nvim` bootstrap が通る
- picker / grep / telescope native build が壊れない
- `mason` 配下の LSP / formatter 導入導線が維持される

## Deferred Items

- `rustowl` を Nix 管理へ移すか、plugin build に委ね続けるかの決定
- `image.nvim` と `luarocks` / `magick` rock をどう再現するかの決定
- `mason` 管理の LSP / formatter を将来的にどこまで Nix 化するかの決定

この 3 点は Phase 1 の完了条件には含めないが、移行後に忘れないよう明示的に backlog として残す。

## リスク

- `mason` 管理外依存の棚卸し漏れがあると移行後に一部機能だけ壊れる
- 既存 symlink が残ったままだと初回 switch で衝突する
- `rustowl` / `image.nvim` を除外することで、一部の Rust / image workflow は一時的に使えなくなる

## 成功条件

- `nvim` 本体が Home Manager 管理になる
- `~/.config/nvim` の source of truth が `nix/home-manager/nvim/` に移る
- `mason` は当面 LSP / formatter 配布責務を維持する
- `mason` 管理外の基盤依存と外部コマンドが Home Manager 管理になる
- `install.sh` が `nvim` を再リンクしない
- `rustowl` / `image.nvim` の除外が文書化され、後続対応項目として残る
