# Yazi クイックガイド

この設定では Yazi の入口が2つあります。

- `yazi`: ターミナルで使うファイルマネージャ。
- `yazi.nvim`: `:Yazi` 経由で Neovim 内に Yazi を開くプラグイン。

このメモ作成時に確認したバージョン: Yazi `26.1.22`、`yazi.nvim` は lazy の plugin checkout。

## Neovim: yazi.nvim

設定場所: `lua/Sethy/plugins/yazi.lua`

| コマンド | キー | できること |
| --- | --- | --- |
| `:Yazi` | `<leader>y` | 現在のファイル位置で Yazi を開く。normal / visual mode で使える。 |
| `:Yazi cwd` | `<leader>Y` | Neovim の current working directory で Yazi を開く。 |
| `:Yazi toggle` | `<C-Up>` | 直前の Yazi session を再開する。 |
| Yazi 内ヘルプ | `<F1>` | floating Yazi window に focus がある間、yazi.nvim の keymap を表示する。 |

Yazi を開いている間に使える yazi.nvim 側のキー:

| キー | できること |
| --- | --- |
| `<C-v>` | 選択したファイルを vertical split で開く。 |
| `<C-x>` | 選択したファイルを horizontal split で開く。 |
| `<C-t>` | 選択したファイルを新しい tab で開く。 |
| `<C-q>` | 選択したファイルを quickfix に送る。 |
| `<C-s>` | 対応 picker がある場合、現在の Yazi directory で検索する。 |
| `<C-y>` | 必要な path tool がある場合、開始ファイルからの相対パスをコピーする。 |
| `<Tab>` | Yazi から Neovim の開いている buffer 間を cycle / jump する。 |

現在の option:

- `open_for_directories = false`: Neovim で directory を開いても yazi.nvim で hijack しない。

## ターミナル: yazi

Yazi を起動する:

```sh
yazi
```

path を指定して起動する:

```sh
yazi path/to/file-or-directory
```

よく使う CLI option:

| コマンド | できること |
| --- | --- |
| `yazi --version` | インストールされている Yazi の version を表示する。 |
| `yazi --debug` | runtime / config / dependency の診断情報を表示する。 |
| `yazi --clear-cache` | Yazi の cache directory を削除する。 |
| `yazi --cwd-file <file>` | 終了時の Yazi cwd を file に書き出す。終了後に `cd` する shell wrapper 用。 |
| `yazi --chooser-file <file>` | Yazi で開いた file path を file に書き出す。script 用。 |
| `ya emit <cmd>` | 現在の Yazi instance に command を送る。 |
| `ya emit-to <id> <cmd>` | 指定した Yazi instance に command を送る。 |
| `ya pkg ...` | Yazi package を管理する。 |

Yazi の代表的な default key:

| キー | できること |
| --- | --- |
| `q` | 終了する。 |
| `F1` or `~` | help を開く。 |
| `h` / `j` / `k` / `l` | 左 / 下 / 上 / 右へ移動する。arrow key も使える。 |
| `gg` / `G` | 先頭 / 末尾へ移動する。 |
| `K` / `J` | preview を上 / 下へ scroll する。 |
| `Space` | 選択状態を toggle する。 |
| `v` / `V` | visual selection / unset mode に入る。 |
| `Ctrl-a` / `Ctrl-r` | 全選択 / 選択反転。 |
| `Esc` | 選択を解除する。 |
| `o` or `Enter` | 選択した file を開く。 |
| `O` or `Shift-Enter` | 選択した file を opener 選択付きで開く。 |
| `Tab` | file 情報を表示する。 |
| `y` / `x` | 選択した file を copy / cut として yank する。 |
| `p` / `P` | paste / overwrite paste する。 |
| `Y` or `X` | yank 状態を解除する。 |
| `d` / `D` | 選択した file を trash / 完全削除する。 |
| `a` | file または directory を作成する。directory は名前の末尾に `/` を付ける。 |
| `r` | 選択した file を rename する。 |
| `.` | hidden files の表示を toggle する。 |
| `c c` / `c d` / `c f` / `c n` | file path / directory path / filename / 拡張子なし filename を copy する。 |
| `f` | file を filter する。 |
| `/` / `?` | 次 / 前を find する。 |
| `n` / `N` | 次 / 前の find result へ移動する。 |
| `s` / `S` | `fd` で filename 検索 / `rg` で content 検索する。 |
| `, n` / `, N` | natural sort / reverse natural sort。 |
| `, s` / `, S` | size sort / reverse size sort。 |
| `t` | current directory で新しい tab を作る。 |
| `1` ... `9` | N 番目の tab に切り替える。 |
| `[` / `]` | 前 / 次の tab へ移動する。 |

## ローカル Yazi 設定

設定場所: `.config/yazi/yazi.toml`

| 設定 | 現在値 | 意味 |
| --- | --- | --- |
| `mgr.ratio` | `[1, 4, 3]` | 親ペイン / 現在ペイン / プレビューペインの幅。 |
| `mgr.sort_by` | `"natural"` | `file2` が `file10` より前に来るような自然順。 |
| `mgr.sort_dir_first` | `true` | directory を file より先に表示する。 |
| `mgr.linemode` | `"size"` | file list に file size を表示する。 |
| `mgr.show_hidden` | `true` | dotfiles をデフォルトで表示する。 |
| `mgr.show_symlink` | `true` | symlink のリンク先を表示する。 |
| `mgr.scrolloff` | `5` | cursor 周辺に 5 行分の余白を残す。 |
| `preview.wrap` | `"yes"` | preview の長い行を折り返す。 |
| `preview.tab_size` | `2` | preview 内の tab を 2 spaces として表示する。 |

参考:

- Yazi Quick Start: https://yazi-rs.github.io/docs/quick-start/
- Yazi 設定 overview: https://yazi-rs.github.io/docs/configuration/overview/
- yazi.nvim README: https://github.com/mikavilpas/yazi.nvim
