---
created: 2026-09-05
updated: 2026-09-05
author: Koki Aoyagi
type: reference
---

# Neovim プラグイン解説

## 概要

プラグインをカテゴリ別に整理：

1. **ファイル操作** - oil.nvim, mini.files
2. **検索・ピッカー** - snacks.nvim
3. **ナビゲーション** - harpoon
4. **編集補助** - mini.comment, mini.surround, mini.splitjoin, mini.trailspace
5. **診断・エラー** - trouble.nvim
6. **フォーマット** - conform.nvim
7. **Markdown** - render-markdown, image-support, after/ftplugin/markdown.lua
8. **コード折りたたみ** - nvim-ufo
9. **ユーティリティ** - undotree, vim-maximizer, noice
10. **LeetCode** - leetcode.nvim
11. **その他のプラグイン** - telescope, auto-session, todo-comments, emmet ほか

---

## 1. ファイル操作

### oil.nvim

バッファとしてディレクトリを編集できるファイラー。

| キー | 動作 |
|------|------|
| `-` | 親ディレクトリを開く |
| `<CR>` | ファイル/ディレクトリを開く |
| `q` | 閉じる |
| `<M-h>` | 水平分割で開く |

**特徴**: ファイル操作（リネーム、削除、移動）をバッファ編集のように行える。

### mini.files

ツリー形式のファイルエクスプローラー。

| キー | 動作 |
|------|------|
| `<leader>ee` | ファイルエクスプローラーを開く |
| `<leader>ef` | 現在のファイルの場所で開く |
| `<CR>` / `L` | ディレクトリに入る / ファイルを開く |
| `-` / `H` | 親ディレクトリに戻る |

---

## 2. 検索・ピッカー (snacks.nvim)

Telescope風のファジーファインダー。

### ファイル検索

| キー | 動作 |
|------|------|
| `<leader>pf` | ファイル検索 |
| `<leader>pc` | Neovim設定ファイルを検索 |
| `<leader>ps` | grep検索 |
| `<leader>pws` | カーソル下の単語/選択範囲をgrep |

### その他

| キー | 動作 |
|------|------|
| `<leader>pk` | キーマップ検索 |
| `<leader>vh` | ヘルプページ検索 |
| `<leader>ts` | カラースキーム選択 |
| `<leader>gbr` | Gitブランチ切り替え |
| `<leader>pt` | TODO コメント検索 |
| `<leader>pT` | TODO/FIX/FIXME 検索 |

### ユーティリティ

| キー | 動作 |
|------|------|
| `<leader>lg` | lazygit を開く |
| `<leader>gl` | lazygit ログ |
| `<leader>cR` | ファイル名をリネーム |
| `<leader>db` | バッファを削除 |

---

## 3. ナビゲーション (harpoon)

頻繁にアクセスするファイルをマーク・ジャンプ。

| キー | 動作 |
|------|------|
| `<leader>a` | 現在のファイルをharpoonリストに追加 |
| `<C-e>` | harpoonメニューを開く |
| `<C-y>` | マーク1番目のファイルへジャンプ |
| `<C-i>` | マーク2番目のファイルへジャンプ |
| `<C-n>` | マーク3番目のファイルへジャンプ |
| `<C-s>` | マーク4番目のファイルへジャンプ |

**使い方**: よく使うファイルを `<leader>a` で追加し、`<C-y>` 〜 `<C-s>` で瞬時にジャンプ。

---

## 4. 編集補助 (mini.nvim)

### mini.comment

コメントのトグル。

| キー | モード | 動作 |
|------|--------|------|
| `gc` | n | 行をコメントトグル |
| `gc` | v | 選択範囲をコメントトグル |
| `gcc` | n | 現在行をコメントトグル |

### mini.surround

囲み文字の追加・削除・変更。

| キー | 動作 | 例 |
|------|------|-----|
| `sa` | 囲みを追加 | `saiw"` → word を `"word"` に |
| `ds` | 囲みを削除 | `ds"` → `"word"` を `word` に |
| `sr` | 囲みを変更 | `sr"'` → `"word"` を `'word'` に |
| `sf` | 囲みを検索（右方向） | |
| `sF` | 囲みを検索（左方向） | |
| `sh` | 囲みをハイライト | |

**Tips**: `[` は空白あり、`]` は空白なしで囲む。

### mini.splitjoin

引数やリストの分割・結合。

| キー | 動作 |
|------|------|
| `sj` | 複数行を1行に結合 |
| `sk` | 1行を複数行に分割 |

**例**:
```javascript
// sk で分割
func(a, b, c)
↓
func(
  a,
  b,
  c
)

// sj で結合
func(
  a,
  b,
  c
)
↓
func(a, b, c)
```

### mini.trailspace

末尾の空白を削除。

| キー | 動作 |
|------|------|
| `<leader>cw` | 末尾の空白を削除 |

---

## 5. 診断・エラー (trouble.nvim)

診断メッセージやTODOをリスト表示。

| キー | 動作 |
|------|------|
| `<leader>xw` | ワークスペース全体の診断 |
| `<leader>xd` | 現在のバッファの診断 |
| `<leader>xq` | quickfixリスト |
| `<leader>xl` | ロケーションリスト |
| `<leader>xt` | TODOコメント一覧 |

### Trouble内の操作

| キー | 動作 |
|------|------|
| `<CR>` | 項目にジャンプ |
| `q` | 閉じる |
| `j` / `k` | 上下移動 |

---

## 6. フォーマット (conform.nvim)

| キー | 動作 |
|------|------|
| `<leader>f` | バッファをフォーマット |

### フォーマッター対応表

| 言語 | フォーマッター |
|------|---------------|
| Lua | stylua |
| JS/TS/JSX/TSX | プロジェクト設定に応じて biome / prettier（整形のみ） |
| JSON | プロジェクト設定に応じて biome / prettier |
| HTML/CSS/SCSS | prettier |
| YAML/Markdown | prettier |
| Nix | alejandra |
| Shell (sh/bash) | shfmt |
| Rust | LSP (rust_analyzer → rustfmt) |
| Python | ruff format |
| Java | jdtls (LSP) |
| Go | goimports → gofumpt |
| C/C++ | clang-format |

**動作**: Rust / TS / Go / Java / Python / C / C++ は保存時に整形する。LSP 整形は Rust / Java のみ。`:FormatToggle` でバッファ単位、`:FormatToggle!` で全体を切り替えられる。

LSP・補完・環境構築・言語ごとの操作は [コーディング環境ガイド](coding-guide.md) を参照。

### Rust 支援

Rust では通常の LSP に加えて次のプラグインが有効。

| プラグイン | 用途 |
|-----------|------|
| **rustaceanvim** (`mrcjkb/rustaceanvim`) | rust-analyzer を rustaceanvim 経由で駆動。`:RustLsp` 系コマンド(runnables / expand macro / hover actions 等)を追加 |
| **bacon** (`nvim-bacon`) | `bacon` の継続チェックを Neovim から利用(下記) |

`rustaceanvim` が `rust-analyzer` の設定を持つ(`rustaceanvim.lua`)。mason の install リストには rust-analyzer を入れていない。

#### bacon

Rust では `bacon` を使った継続チェックも利用可能。

| キー | 動作 |
|------|------|
| `<leader>lb` | 下部ターミナルで `bacon` を開閉 |
| `<leader>lB` | `bacon` の locations 一覧を開く |
| `<leader>lj` | 次の `bacon` エラー/警告へ移動 |
| `<leader>lk` | 前の `bacon` エラー/警告へ移動 |

一覧ウィンドウ内では `Ctrl-j` / `Ctrl-k` で上下移動できる。

`nvim-bacon` は `.bacon-locations` を読むので、`~/.config/bacon/prefs.toml` などで locations export を有効化する必要がある。

```toml
[exports.locations]
auto = true
path = ".bacon-locations"
line_format = "{item-idx}: {kind} {path}:{line}:{column} {message}"

listen = true
```

`bacon` を別 pane や `<leader>lb` で起動しておくと、診断結果が quickfix に反映され、`Trouble quickfix` (`<leader>xq`) から一覧確認もできる。

## 7. Markdown

### render-markdown.nvim

Markdownをリッチに装飾表示するプラグイン。

| 機能 | 説明 |
|------|------|
| 見出し | `#` をアイコン（󰎤 󰎧 など）に置換、背景色付き |
| コードブロック | ブロック幅で背景色、言語表示 |
| チェックボックス | `[ ]` → 󰄱、`[x]` → 󰱒 に置換 |
| 箇条書き | `-` を装飾アイコンに |
| テーブル | 罫線を綺麗に描画 |

### image-support (img-clip.nvim + image.nvim)

Markdown内に画像を貼り付け・表示。

**img-clip.nvim** - クリップボードから画像を貼り付け

| キー | 動作 |
|------|------|
| `<leader>pi` | クリップボードから画像を貼り付け |

- 画像は `assets/` ディレクトリに保存
- `![alt](path)` 形式で挿入

**image.nvim** - ターミナル内で画像を表示

- Kittyグラフィックプロトコル使用（WezTerm対応）
- Markdownの画像リンクを自動検出して表示
- 依存: `pngpaste`, `imagemagick`, `luarocks magick`

### after/ftplugin/markdown.lua

Markdownファイル専用のカスタム設定。

**基本設定（自動適用）**

| 設定 | 説明 |
|------|------|
| `textwidth = 80` | 80文字で自動改行 |
| `spell = true` | スペルチェック有効 |
| `linebreak = true` | 単語の途中で改行しない |

**リスト操作キーマップ（Normal / Visual）**

| キー | 動作 |
|------|------|
| `tn` | 番号付きリスト トグル |
| `tb` | 箇条書き（`-`）トグル |
| `tc` | チェックボックス トグル |
| `tt` | タスク状態 `[ ]` ↔ `[x]` トグル |
| `tl` | スマートトグル（プレーン → 箇条書き → チェックボックス → 番号 → プレーン） |

**見出し操作**

| キー | 動作 |
|------|------|
| `<leader>h1` 〜 `h6` | 見出しレベル トグル |

**タスク一括操作**

| キー | 動作 |
|------|------|
| `<leader>tc` | 全タスクを完了にする |
| `<leader>tu` | 全タスクを未完了にする |

---

## 8. コード折りたたみ (nvim-ufo)

Treesitterベースの高速な折りたたみ。

| キー | 動作 |
|------|------|
| `za` | カーソル位置の折りたたみトグル |
| `zR` | 全ての折りたたみを開く |
| `zM` | 全ての折りたたみを閉じる |

- 起動時は全て展開（`foldlevel = 99`）
- 関数、クラス、if文などを折りたたんでコードを俯瞰可能

---

## 9. ユーティリティ

### undotree

変更履歴をツリー形式で表示・復元。

| キー | 動作 |
|------|------|
| `<leader>u` | 外部 undotree をトグル |
| `<leader>U` | builtin undotree を開く |

### vim-maximizer

分割ウィンドウの最大化/復元。

| キー | 動作 |
|------|------|
| `<leader>sm` | 現在のウィンドウを最大化/元に戻す |

### noice.nvim

UIの改善（コマンドライン、メッセージ、通知）。

- `:` でポップアップコマンドライン
- `/` `?` で検索ポップアップ
- LSP hover / markdown UI の改善
- メッセージを通知スタイルで表示

---

## 10. LeetCode

### leetcode.nvim

LeetCode の問題一覧、問題文表示、実行、提出を Neovim 内で行うプラグイン。

この設定では custom keymap は足していないので、`:` から `Leet` コマンドを直接使う。

### よく使うコマンド

| コマンド | 動作 |
|---------|------|
| `:Leet` | ダッシュボードを開く |
| `:Leet list` | 問題一覧を開く |
| `:Leet daily` | 今日の問題を開く |
| `:Leet run` | 現在の問題を実行 |
| `:Leet submit` | 現在の回答を提出 |
| `:Leet lang` | 問題の言語を切り替える |
| `:Leet info` | 問題情報ポップアップ |
| `:Leet cookie update` | ログイン用 cookie を更新 |

### 使い方メモ

- デフォルト言語は `Rust`
- 必要に応じて `:Leet lang` で `Go` / `C++` へ切り替える
- `leetcode.com` 前提で設定しているので、中国版サイトは使わない
- 既存セッション中でも `:Leet` で開けるよう `non_standalone` を有効化している

### ログイン

1. ブラウザで `leetcode.com` にログイン
2. 開発者ツールの request headers から `Cookie` をコピー
3. `:Leet cookie update` を実行して貼り付ける

注意: `set-cookie` ではなく request headers の `Cookie` を使う。

---

## 11. その他のプラグイン

上の節に載っていないが有効なプラグイン。日常的にキーを叩くものは keymap 付き、裏方は一覧のみ。

### telescope.nvim

fzf-native と themes 拡張を組み込んだファジーピッカー。多くの検索は `snacks.nvim` 側(2 節)に寄せているが、telescope 固有の操作が残る。

| キー | 動作 |
|------|------|
| `<leader>pr` | 現在プロジェクト内の最近使ったファイルを検索 |
| `<leader>pWs` | カーソル下の `<cWORD>` を grep |
| `<leader>th` | テーマ切り替え(`Telescope themes`) |

- insert モードのリスト移動は `<C-j>` / `<C-k>`、normal モードは `q` で閉じる
- 選んだテーマは `stdpath("state")/current-theme.lua` に永続化される

### auto-session

cwd 単位でセッション(開いていたバッファ・レイアウト)を保存・復元する。

| キー | 動作 |
|------|------|
| `<leader>wr` | cwd のセッションを復元 |
| `<leader>ws` | cwd のセッションを保存 |

### todo-comments.nvim

`TODO` / `FIX` / `HACK` / `WARN` / `PERF` / `NOTE` / `TEST` などのコメントをアイコン付きでハイライトし、ジャンプできる。検索は `rg` を使う。

| キー | 動作 |
|------|------|
| `]t` | 次の TODO コメントへ |
| `[t` | 前の TODO コメントへ |

一覧は `Trouble todo`(5 節)からも開ける。

### nvim-emmet

HTML/CSS の emmet 展開のうち、既存の選択範囲を abbreviation で包む用途だけに絞って使う(補完自体は mason の `emmet_ls` が担当)。

| キー | 動作 |
|------|------|
| `<leader>xe` (n/v) | 選択範囲を emmet abbreviation で wrap |

### 裏方・自動有効プラグイン

キーを直接叩くことは少ないが、常時効いているもの。

| プラグイン | repo | 役割 |
|-----------|------|------|
| blink.cmp | `Saghen/blink.cmp` | 補完エンジン(LSP / snippet / path) |
| nvim-treesitter | `nvim-treesitter/nvim-treesitter` | 構文解析ベースのハイライト・textobject |
| nvim-autopairs | `windwp/nvim-autopairs` | 括弧・クォートの自動補完 |
| mason.nvim | `williamboman/mason.nvim` | LSP / formatter / linter のインストーラ(`mason.lua` 参照) |
| lualine.nvim | `nvim-lualine/lualine.nvim` | ステータスライン |
| incline.nvim | `b0o/incline.nvim` | 各ウィンドウ右上のファイル名表示 |
| wilder.nvim | `gelguy/wilder.nvim` | コマンドライン補完 UI |
| nvcode-color-schemes | `ChristianChiarulli/nvcode-color-schemes.vim` | カラースキーム |
| showkeys | `nvzone/showkeys` | 押下キーの画面表示(スクリーンキャスト用) |
| nvim-colorizer | `NvChad/nvim-colorizer.lua` | 色コードのインラインプレビュー(`tailwind-tools.lua` で読み込み) |

> repo 名と実装ファイル名が一致しないものがある: `tailwind-tools.lua` は実際には `nvim-colorizer` を読み込んでいる。

---

## LSP キーマップ (lspconfig.lua)

LSPがアタッチされたバッファで使用可能。

### ナビゲーション

| キー | 動作 |
|------|------|
| `gd` | 定義へジャンプ |
| `gD` | 宣言へジャンプ |
| `gR` | 参照一覧 |
| `gi` | 実装へジャンプ |
| `gt` | 型定義へジャンプ |
| `K` | ホバードキュメント |

### 診断

| キー | 動作 |
|------|------|
| `<leader>d` | 行の診断をフロート表示 |
| `<leader>D` | バッファ全体の診断 (Telescope) |
| `<leader>lx` | 診断表示のトグル |

### リファクタリング

| キー | 動作 |
|------|------|
| `<leader>rn` | シンボルをリネーム |
| `<leader>vca` | コードアクション |

### その他

| キー | 動作 |
|------|------|
| `<leader>rs` | LSP再起動 |
| `<C-h>` (insert) | シグネチャヘルプ |

---

## 基本キーマップ (keymaps.lua)

### 移動

| キー | 動作 |
|------|------|
| `<C-d>` | 半ページ下（カーソル中央維持） |
| `<C-u>` | 半ページ上（カーソル中央維持） |
| `n` / `N` | 検索結果移動（カーソル中央維持） |

### 編集

| キー | モード | 動作 |
|------|--------|------|
| `J` / `K` | v | 選択行を上下に移動 |
| `<` / `>` | v | インデント（選択維持） |
| `<leader>p` | v | ペースト（レジスタ上書きなし） |
| `<leader>d` | n, v | 削除（レジスタに入れない） |
| `x` | n | 1文字削除（レジスタに入れない） |

### ウィンドウ・タブ

| キー | 動作 |
|------|------|
| `<leader>sv` | 縦分割 |
| `<leader>sh` | 横分割 |
| `<leader>se` | 分割を均等化 |
| `<leader>sx` | 分割を閉じる |
| `<leader>to` | 新しいタブ |
| `<leader>tx` | タブを閉じる |
| `<leader>tn` | 次のタブ |
| `<leader>tp` | 前のタブ |

### その他

| キー | 動作 |
|------|------|
| `<C-c>` | 検索ハイライトをクリア |
| `<leader>r` | カーソル下の単語を置換 |
| `<leader>x` | ファイルを実行可能にする |
| `<leader>fp` | ファイルパスをクリップボードにコピー |
| `<leader>L` | Lazy.nvim UIを開く |

---

## Leader キー

`<Space>` がリーダーキーとして設定されている。
