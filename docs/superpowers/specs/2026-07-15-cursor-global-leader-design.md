# Cursor Global Leader Fallback Design

## 目的

Cursor でファイルタブが開いていない場合や、Explorer、Search、Source Control などへフォーカスしている場合でも、Neovim と同じ `<Space>` 起点のワークベンチ操作を使えるようにする。

## 原因

現在の `<Space>pf`、`<Space>ps`、`<Space>ee`、`<Space>gg` は `nvim-vscode/init.lua` に定義されている。これらは vscode-neovim がテキストエディタへアタッチしてキーを受け取れる場合にだけ動作するため、空のエディタグループやサイドバーでは発火しない。

Cursor 3.11.19 のキーバインドパーサーは3ストローク以上の chord を扱えるため、Cursor ネイティブのキーバインドをフォールバックとして使用できる。

## 設計

既存の Neovim マッピングは維持し、Cursor の `keybindings.json` に次の4つのネイティブフォールバックを追加する。

| キー | Cursor command | 用途 |
| --- | --- | --- |
| `space p f` | `workbench.action.quickOpen` | ファイル検索 |
| `space p s` | `workbench.action.findInFiles` | 全文検索 |
| `space e e` | `workbench.view.explorer` | Explorerを開く |
| `space g g` | `workbench.view.scm` | Source Controlを開く |

各フォールバックには次の `when` 条件を付ける。

```text
!editorTextFocus && !inputFocus && !terminalFocus && !accessibleViewIsShown && !accessibilityHelpIsShown
```

これにより処理経路を次のように分離する。

- テキストエディタ: 既存のNeovim Luaマッピングが処理する。
- 空のエディタグループ、Welcome画面、非入力状態のサイドバー: Cursorネイティブフォールバックが処理する。
- Search、SCM、Chatなどの入力欄: chordを開始せず、通常の文字入力を維持する。
- Terminal: chordを開始せず、Terminalへキーを渡す。
- Accessible ViewとAccessibility Help: 補助UI固有の操作を優先する。

Lua側とCursor側の条件が重ならないため、同じキー操作からコマンドが二重実行されることはない。vscode-neovimの初期化状態をCursor側の条件に含めず、フォールバックをNeovim拡張から独立させる。

`<Space>pws` はカーソル下の単語を検索語として渡す操作であり、エディタがない状態では意味を持たないため、Neovim側だけに残す。LSP操作や移動操作も今回の対象外とする。

## 設定の所有とロールバック

既存のCursorユーザー設定69件は保持し、4件だけを末尾へ追加する。適用前の `keybindings.json` を日時入りの別ファイルへバックアップし、問題があればバックアップを戻すだけで復旧できるようにする。

今回、Cursorユーザー設定全体をHome Manager管理へ移すことはしない。dotfilesには設計、実装計画、および再現可能な検証条件を残し、既存のローカル設定との境界を維持する。

## 検証

自動検証では次を確認する。

- `keybindings.json` がJSONCとして有効である。
- 既存69件が意味的に変化していない。
- 追加された4件のキー、command、`when` が設計どおりで、重複がない。
- `nvim-vscode/init.lua` と既存Neovimテストが変更されていない、または従来どおり通る。
- dotfilesの通常Neovim設定が影響を受けていない。

手動スモークテストでは、空のエディタグループ、Explorer、Source Controlから4つのchordが動くこと、各種入力欄とTerminalでSpaceを含む通常入力が壊れていないこと、テキストエディタのNormal modeでは従来のNeovimマッピングが動くことを確認する。
