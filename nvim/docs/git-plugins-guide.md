# Neovim Git ワークフロー ガイド

## 主要プラグイン

| プラグイン | 用途 |
|-----------|------|
| **gitsigns.nvim** | hunk単位の変更操作・可視化 |
| **lazygit** (snacks.nvim経由) | フルスクリーンGit TUI |

---

## gitsigns.nvim

バッファ左端に変更マーク表示。hunk（変更の塊）単位で細かく操作できる。

### 基本思想

- **コード書きながらGit操作** → gitsigns
- 編集中に「この部分だけstage」「この変更だけ取り消し」が可能
- コミットまではしない（lazygitまたはfugitiveで行う）

### キーマップ一覧

#### ステージング

| キー | モード | 動作 |
|------|--------|------|
| `<leader>gs` | n | hunkをstage |
| `<leader>gs` | v | 選択範囲をstage |
| `<leader>gS` | n | バッファ全体をstage |
| `<leader>gu` | n | stage取り消し |

#### リセット（変更破棄）

| キー | 動作 |
|------|------|
| `<leader>gr` | hunkをリセット |
| `<leader>gR` | バッファ全体をリセット |

#### 確認・Diff

| キー | 動作 |
|------|------|
| `<leader>gp` | hunkをポップアップでプレビュー |
| `<leader>gd` | HEADとのdiff |
| `<leader>gD` | 前コミットとのdiff |

#### Blame

| キー | 動作 |
|------|------|
| `<leader>gbl` | 現在行の詳細blame |
| `<leader>gB` | 行末blame表示トグル |

#### ナビゲーション

| キー | 動作 |
|------|------|
| `]h` | 次のhunkへ |
| `[h` | 前のhunkへ |

#### テキストオブジェクト

| キー | モード | 例 |
|------|--------|-----|
| `ih` | o, x | `dih` でhunk削除、`vih` でhunk選択 |

### 典型的な使い方

```
]h / [h         " hunk間を移動
<leader>gp      " 内容確認
<leader>gs      " 良ければstage
<leader>gr      " 不要なら破棄
```

---

## lazygit

ターミナルベースのGit TUI。複雑な操作（rebase, cherry-pick, stash等）はこちらで。

### 起動

| キー | 動作 |
|------|------|
| `<leader>lg` | lazygitを開く |
| `<leader>gl` | lazygit ログビューで開く |

### パネル構成

起動すると5つのパネルが表示される：

```
┌─────────────┬─────────────────────────┐
│ 1. Status   │                         │
├─────────────┤  5. Main (diff/log)     │
│ 2. Files    │                         │
├─────────────┤                         │
│ 3. Branches │                         │
├─────────────┤                         │
│ 4. Commits  │                         │
└─────────────┴─────────────────────────┘
```

### パネル移動

| キー | 動作 |
|------|------|
| `1-5` | 各パネルへ直接移動 |
| `h/l` または `Tab/Shift+Tab` | パネル間移動 |
| `j/k` | パネル内で上下移動 |

### Files パネル（最頻出）

| キー | 動作 |
|------|------|
| `Space` | stage/unstage |
| `a` | 全ファイルをstage/unstage |
| `c` | コミット |
| `A` | amend（前コミットに追加） |
| `d` | 変更を破棄（unstaged） |
| `D` | 破棄オプション表示 |
| `e` | ファイルを編集 |
| `Enter` | ファイルのhunk選択画面へ |

### hunk選択（Enter後）

| キー | 動作 |
|------|------|
| `Space` | 選択行/hunkをstage |
| `d` | 選択行/hunkを破棄 |
| `v` | 範囲選択モード |
| `a` | hunk全体を選択 |
| `Esc` | 戻る |

### Branches パネル

| キー | 動作 |
|------|------|
| `Space` | checkout |
| `n` | 新規ブランチ |
| `d` | 削除 |
| `r` | rebase onto |
| `M` | merge into current |
| `P` | pull |
| `p` | push |
| `u` | upstream設定 |

### Commits パネル

| キー | 動作 |
|------|------|
| `c` | cherry-pick (copy) |
| `v` | cherry-pick (paste) |
| `r` | reword（メッセージ編集） |
| `s` | squash |
| `f` | fixup |
| `d` | drop |
| `e` | edit（rebase中断） |
| `g` | reset options |

### Stash

| キー | 動作 |
|------|------|
| `s` | stash |
| `S` | stash options |
| `g` | stash pop |

### グローバル

| キー | 動作 |
|------|------|
| `?` | ヘルプ表示 |
| `q` | 終了 |
| `/` | 検索 |
| `+/-` | diff context行数増減 |
| `@` | コマンドログ |
| `P` | push |
| `p` | pull |

---

## 使い分けガイド

### gitsignsを使う場面

- コード編集中の細かいstage/破棄
- 「この関数だけstage」
- 変更箇所のナビゲーション
- 誰がいつ書いたか確認（blame）

### lazygitを使う場面

- コミット作成
- ブランチ操作
- rebase / merge
- cherry-pick
- 履歴確認
- 複雑なstash操作

---

## 推奨ワークフロー

### 1. 機能開発中

```
[コーディング]
]h / [h         " 変更箇所を確認
<leader>gp      " diff確認
<leader>gs      " 良いhunkをstage

[コミット時]
<leader>lg      " lazygit起動
c               " コミット
```

### 2. 部分的な変更だけコミット

```
<leader>lg      " lazygit起動
Enter           " ファイルのhunk画面へ
v               " 範囲選択
Space           " 選択部分をstage
Esc             " 戻る
c               " コミット
```

### 3. 直前コミットを修正

```
<leader>lg
A               " amend
```

### 4. 変更を一時退避

```
<leader>lg
s               " stash
[作業]
g               " stash pop
```

### 5. ブランチ切り替え

```
<leader>lg
3               " Branchesパネルへ
/検索           " ブランチ検索
Space           " checkout
```

---

## 補足: vim-fugitive

`<leader>gg` でfugitiveステータス画面も使用可能。軽量な操作向け。
lazygitが重く感じる場合の代替として。
