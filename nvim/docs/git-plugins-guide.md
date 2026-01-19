# Neovim Git プラグイン解説

## 概要

3つのgit関連プラグインが設定されている：

1. **vim-fugitive** - Gitコマンド実行
2. **gitsigns.nvim** - 変更箇所の可視化・操作
3. **git-worktree.nvim** - worktree管理

---

## 1. vim-fugitive

Vimから直接Gitコマンドを実行できるプラグイン。

### キーマップ

| キー         | 動作                                       | 場所           |
| ------------ | ------------------------------------------ | -------------- |
| `<leader>gg` | Gitステータス画面を開く                    | どこでも       |
| `<leader>P`  | `git push`                                 | fugitive画面内 |
| `<leader>p`  | `git pull --rebase`                        | fugitive画面内 |
| `<leader>t`  | `git push -u origin ` (ブランチ名入力待ち) | fugitive画面内 |

### 基本操作（fugitive画面内）

`:Git` (または `<leader>gg`) でステータス画面を開いた後：

| キー        | 動作                  |
| ----------- | --------------------- |
| `s`         | ファイルをstage       |
| `u`         | ファイルをunstage     |
| `=`         | diffを展開/折りたたみ |
| `cc`        | コミット              |
| `ca`        | amend commit          |
| `X`         | 変更を破棄（危険）    |
| `<Enter>`   | ファイルを開く        |
| `dv`        | vertical diff         |
| `]c` / `[c` | 次/前の変更へ移動     |

### よく使うコマンド

```vim
:Git blame          " 行ごとのblame表示
:Git log            " ログ表示
:Git diff           " 差分表示
:Gvdiffsplit        " 縦分割でdiff
:Gread              " HEADの内容で上書き（変更破棄）
:Gwrite             " 現在のバッファをstage
```

---

## 2. gitsigns.nvim

バッファ内の変更箇所を左側のサインで可視化し、hunk単位で操作できる。

### hunkとは？

連続した変更行のまとまり。ファイル全体ではなく、変更の塊ごとに操作できる。

### キーマップ

#### ステージング操作

| キー         | モード | 動作                |
| ------------ | ------ | ------------------- |
| `<leader>gs` | n      | hunkをstage         |
| `<leader>gs` | v      | 選択範囲をstage     |
| `<leader>gS` | n      | バッファ全体をstage |
| `<leader>gu` | n      | stageを取り消し     |

#### リセット操作

| キー         | 動作                       |
| ------------ | -------------------------- |
| `<leader>gr` | hunkをリセット（変更破棄） |
| `<leader>gR` | バッファ全体をリセット     |

#### プレビュー・差分

| キー         | 動作                             |
| ------------ | -------------------------------- |
| `<leader>gp` | hunkをプレビュー（ポップアップ） |
| `<leader>gd` | HEADとのdiff                     |
| `<leader>gD` | 前のコミットとのdiff             |

#### Blame

| キー          | 動作                  |
| ------------- | --------------------- |
| `<leader>gbl` | 現在行のblame（詳細） |
| `<leader>gB`  | 行末blame表示のトグル |

#### ナビゲーション

| キー | 動作           |
| ---- | -------------- |
| `]h` | 次のhunkへ移動 |
| `[h` | 前のhunkへ移動 |

#### テキストオブジェクト

| キー | モード | 動作                                 |
| ---- | ------ | ------------------------------------ |
| `ih` | o, x   | hunk内を選択（例: `dih` でhunk削除） |

---

## 3. git-worktree.nvim

Git worktreeをTelescope経由で管理。複数ブランチを同時に作業ディレクトリとして保持できる。

### worktreeとは？

通常gitは1つの作業ディレクトリしか持てないが、worktreeを使うと複数のブランチを別々のディレクトリで同時にチェックアウトできる。

例：mainで作業中にhotfixが必要 → worktreeで別ディレクトリにhotfixブランチを展開

### キーマップ

| キー         | 動作                 |
| ------------ | -------------------- |
| `<leader>wl` | worktree一覧を表示   |
| `<leader>wc` | 新しいworktreeを作成 |

### Telescope内の操作

| キー      | 動作                       |
| --------- | -------------------------- |
| `<Enter>` | 選択したworktreeに切り替え |
| `<C-d>`   | worktreeを削除             |
| `<C-f>`   | 強制削除モードをトグル     |

---

## よくあるワークフロー

### 1. 変更をコミット

```
<leader>gg      " fugitive画面を開く
s               " 変更ファイルをstage
cc              " コミットメッセージ入力
:wq             " 保存してコミット完了
<leader>P       " push
```

### 2. 特定の変更だけコミット（hunk単位）

```
]h              " 次のhunkへ移動
<leader>gp      " プレビューで確認
<leader>gs      " このhunkだけstage
<leader>gg      " fugitiveでコミット
```

### 3. 変更を確認してから破棄

```
<leader>gd      " 差分を確認
<leader>gr      " hunkを破棄
# または
<leader>gR      " ファイル全体の変更を破棄
```

### 4. 誰がいつ書いたか確認

```
<leader>gbl     " 詳細なblame
<leader>gB      " 常時blame表示トグル
```

---

## Leader キー

設定によるが、一般的には `<Space>` または `\`
