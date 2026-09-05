---
created: 2026-09-05
author: Koki Aoyagi
type: runbook
---

# Neovim コーディング環境

Neovim 0.12 以降を前提に、Rust / TypeScript / Go / Java / Python / C / C++ を支援する。
LSP の設定・有効化は `lua/Sethy/core/servers.lua` を基準にし、Mason の導入一覧もそこから作る。
Rust は rustaceanvim、Java は nvim-jdtls がクライアントの起動を担当する。

## 言語ごとの役割

| 言語 | 型情報・補完・定義ジャンプ | 診断 | 保存時の整形 |
| --- | --- | --- | --- |
| Rust | rust-analyzer / rustaceanvim | rust-analyzer + Clippy（導入時） | rust-analyzer 経由の rustfmt |
| TS / TSX / JS / JSX | ts_ls | TypeScript + 設定のあるプロジェクトで Biome / ESLint | 近い階層の Biome / Prettier 設定を採用 |
| Go | gopls | gopls / staticcheck | goimports → gofumpt |
| Java | jdtls / nvim-jdtls | jdtls | jdtls |
| Python | Pyright | Pyright の型検査 + Ruff の lint | ruff format |
| C / C++ | clangd | clangd / clang-tidy | clang-format |

Lua / Nix / shell と、TS 開発で使う HTML / CSS / Tailwind / Emmet も残す。
Zig / Astro / Svelte の専用 LSP は自動導入・有効化から外した。
RustOwl の無効な設定、未構成の nvim-dap 依存、未使用の nvim-cmp 向けカラー表示依存も削除した。
既存の Mason パッケージや Lazy のキャッシュは自動削除しない。

## 初回導入・反映

1. 通常の dotfiles 反映を実行する。macOS は repo ルートで
   `sudo darwin-rebuild switch --flake ./nix#KokiAoyagi`、
   Linux は `home-manager switch --flake ./nix#kokiaoyagi`。
   Git flake に新規ファイルを含めるため、追加ファイルを Git の管理対象にしてから実行する。
2. Rust の toolchain に `rustup component add rust-analyzer rustfmt clippy` を導入する。
   `rust-toolchain.toml` があるプロジェクトではその toolchain にも必要。
3. Neovim を起動して `:Lazy install` を実行し、nvim-jdtls などの導入完了を待つ。
   `:Lazy update rustaceanvim` で Neovim 0.12 対応の v9 系へ更新する。
4. `:Mason` でサーバを確認。`:MasonToolsInstall` で goimports などの整形ツールを導入できる。
5. Treesitter は不足パーサを起動時に非同期で導入する。初回はネットワーク接続と
   `tree-sitter` CLI / C compiler / curl / tar が必要。更新後は `:TSUpdate`。

設定は Home Manager が Nix store 経由で配置するため、repo のファイル変更だけでは
既に開いている Neovim に反映されない。反映後に Neovim を再起動する。

Nix で導入済みの clangd / clang-format / lua-language-server と、
mise / rustup / プロジェクトの PATH を Mason より優先する。
不足するツールは Mason が補う。Node と Go の runtime は mise、Python 環境は uv など、
Java の JDK は mise が引き続き管理する。Mason はプロジェクトの runtime を導入しない。

## よく使う操作

`<leader>` は Space。

| 操作 | キー / コマンド |
| --- | --- |
| 定義 / 宣言 / 実装 / 型定義 | `gd` / `gD` / `gi` / `gt` |
| 参照一覧 | `gR` |
| シンボル名変更 | `<leader>rn` |
| ファイル名変更（LSP にも通知） | `<leader>cR` |
| Code action | `<leader>ca` または既存の `<leader>vca` |
| import 整理 | `<leader>co` |
| ドキュメント | `K` |
| 引数の signature help | 入力時に自動表示 / Insert mode の `Ctrl-s` |
| ファイル内 / workspace のシンボル一覧 | `<leader>cs` / `<leader>cS` |
| Inlay hints の切り替え | `<leader>ch`（対応サーバで利用可能） |
| 行の診断 / ファイルの診断一覧 | `<leader>cd` / `<leader>D` |
| 前 / 次の診断 | `[d` / `]d`（Neovim 標準） |
| LSP 再起動 | `<leader>rs` |
| バッファ / 選択範囲の整形 | `<leader>cf` または既存の `<leader>f` |
| 保存時整形をバッファ単位で切り替え | `:FormatToggle` |
| 保存時整形を全体で切り替え | `:FormatToggle!` |
| formatter の選択と実行状態 | `:ConformInfo` |

LSP の行診断を `<leader>d` から移動し、既存の black-hole delete と区別した。
Insert mode の `Ctrl-h` は backspace のまま使える。
friendly-snippets は LuaSnip に読み込み、blink.cmp の候補から利用できる。

保存時は最大2秒待つ。大きなファイルや初期化中のサーバで時間がかかる場合は、
手動整形を使う。自動整形を無効にしても手動整形は使える。
未登録の言語に対して別の LSP formatter を勝手に選ぶことはしない。

## プロジェクトごとの設定

### Rust

保存時チェックを有効にした。Clippy があれば rustaceanvim が Clippy を使い、
なければ通常のチェックを使う。`cargo.allFeatures` の一律強制は外したため、
排他的な feature のあるプロジェクトでもデフォルト feature で解析する。

| 操作 | キー |
| --- | --- |
| 実行対象を選ぶ | `<leader>lr` |
| テスト対象を選ぶ | `<leader>lt` |
| マクロ展開 | `<leader>lm` |
| bacon を開閉 | `<leader>lb` |
| bacon の locations | `<leader>lB` |
| 次 / 前の bacon 診断 | `<leader>lj` / `<leader>lk` |

bacon は任意。bacon を常用して重複チェックを止める場合は、
`:RustAnalyzer config { checkOnSave = false }` で現在のサーバだけ切り替えられる。

v9 系は `.vscode/settings.json` を自動で読み込まない。永続的な上書きは
Neovim の `vim.lsp.config("rust-analyzer", { settings = ... })` などで指定する。

### TypeScript

Biome の設定がある場合は `biome format`、Prettier の設定がある場合は Prettier を使う。
両方ある場合はファイルに近い設定を選び、同じ階層なら Prettier を優先する。
どちらもない場合も Prettier を使う。`package.json` の `prettier` 設定にも対応する。
プロジェクトの `node_modules/.bin` に formatter があれば、そのバージョンを使う。

保存時に `biome check --write` は実行しない。lint 修正・import 整理は
code action から明示的に実行する。これにより書きかけの未使用 import を保存のたびに削除しない。
ESLint はプロジェクト側に `eslint` と設定ファイルを用意する。
Biome と ESLint を併用する場合は、それぞれのルールをプロジェクト側で分担する。

### Go

`go.mod` / `go.work` を使って gopls が workspace を判定する。
保存時の goimports で不足 import の追加・未使用 import の削除を行い、その後 gofumpt で整形する。
解析対象の Go に対応した gopls が必要。

### Python

型検査は Pyright の basic をデフォルトにし、`pyrightconfig.json` /
`pyproject.toml` でプロジェクトの設定を指定できる。Ruff のために型検査全体を無効にはしない。

Python interpreter は、明示設定があればそれを維持する。
それ以外では、有効な `VIRTUAL_ENV` → プロジェクトの `.venv` → `CONDA_PREFIX` の順に探す。
見つからなければ Pyright 自体の環境解決に任せる。
`uv sync` などで依存を導入し、環境を作成・切り替えた後は `<leader>rs` で再起動する。
保存時は Ruff の整形のみ。lint 修正と import 整理は code action で行う。

### Java

起動用 JDK は21以降が必要。古い Java を使うプロジェクトでは、jdtls を起動する JDK と
ビルド対象の JDK を分ける。必要に応じて `settings.java.configuration.runtimes` を指定し、
`:JdtSetRuntime` で選択する。プロジェクトの language level は Maven / Gradle で指定する。

Gradle settings / Maven・Gradle wrapper を module 内の build ファイルより優先し、
複数モジュールで1つのクライアントを共有する。index はプロジェクトの絶対パスをハッシュ化し、
`stdpath("state")/jdtls-workspaces/` に分離する。単独ファイルも起動するが、
完全なプロジェクト解析には Maven / Gradle の設定が必要。

`<leader>cv` で変数抽出、Visual mode の `<leader>cm` でメソッド抽出。
`:JdtCompile`、`:JdtUpdateConfig` でコンパイルと build 設定の再取り込みができる。

### C / C++

正確な include path・define・コンパイルフラグには `compile_commands.json` が必要。
CMake なら次のように生成する。

```sh
cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

build ディレクトリが自動検出されない場合は、プロジェクトの `.clangd` で指定する。

```yaml
CompileFlags:
  CompilationDatabase: build
```

整形ルールは `.clang-format`、追加の診断ルールは `.clang-tidy` で指定する。
クロスコンパイルでは実際の compiler に合わせて `--query-driver` を限定して設定する。

## 確認

- `:checkhealth vim.lsp`: サーバ、root、コマンド。
- `:checkhealth mason`: インストーラの依存。
- `:checkhealth nvim-treesitter`: パーサと compiler。
- `:ConformInfo`: 実際に選ばれた formatter とログ。
- `:messages`、`:JdtShowLogs`: 起動失敗の詳細。

repo の回帰テストは `./tests/run.sh`、個別には `nvim --headless -l tests/<name>_test.lua` で実行する。
整形テストは導入済み conform.nvim を利用する。
別の場所にプラグインがある場合は `NVIM_TEST_PLUGIN_DIR` に Lazy の root を指定する。
Conform / Biome がない場合の integration test は skip と明示する。

## 参照

- [Conform の設定](https://github.com/stevearc/conform.nvim)
- [Ruff と Pyright の併用](https://docs.astral.sh/ruff/editors/setup/)
- [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)
- [nvim-jdtls](https://github.com/mfussenegger/nvim-jdtls)
- [Treesitter のパーサ導入](https://github.com/nvim-treesitter/nvim-treesitter)
- [clangd の compilation database](https://clangd.llvm.org/installation#project-setup)
