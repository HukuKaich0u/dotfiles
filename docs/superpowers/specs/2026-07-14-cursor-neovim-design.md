# Cursor 専用 Neovim 設定設計

## 目的

Cursor のエディタ領域で実際の Neovim を編集バックエンドとして使い、普段のターミナル版 Neovim に近い操作感を得る。同時に、既存の Neovim 設定・プラグイン・状態・キャッシュから Cursor 用設定を完全に切り離し、片方の変更がもう片方を壊さない構成にする。

## スコープ

この変更は次を対象とする。

- vscode-neovim 拡張機能の導入
- Cursor 専用 Neovim 設定の dotfiles 管理
- Home Manager による Cursor 専用設定の配置
- Cursor の端末固有設定への Neovim 実行ファイルと `NVIM_APPNAME` の指定
- Neovim ノーマルモードを優先する範囲に限った Cursor キーバインド競合の整理
- ファイル検索、コードナビゲーション、Editor Group 移動に必要な最小キーマップ

次は対象外とする。

- 通常版 Neovim 設定の変更
- Cursor の `settings.json` 全体の dotfiles 管理
- Cursor 専用 Neovim へのプラグインマネージャー導入
- Telescope、Snacks、Oil、Yazi、Harpoon、Gitsigns、Neovim LSP、補完、formatter の移植
- Cursor のターミナル、Composer、Notebook に関する既存キーバインドの変更

## 採用方式

Cursor の `vscode-neovim.NVIM_APPNAME` を `nvim-vscode` に設定する。

これにより、Cursor 内の Neovim は通常版とは別の標準パスを使う。

```text
~/.config/nvim-vscode
~/.local/share/nvim-vscode
~/.local/state/nvim-vscode
~/.cache/nvim-vscode
```

別の `init.lua` を `-u` 相当で指定する方式と異なり、設定だけでなくデータ・状態・キャッシュも分離できる。既存 `init.lua` を `vim.g.vscode` で分岐する方式は採用しない。

## ファイルと責務

```text
dotfiles/
└── nix/modules/home/assets/
    ├── nvim/                 # 既存の通常版 Neovim。変更しない
    └── nvim-vscode/
        └── init.lua          # Cursor 専用の最小設定
```

Home Manager は次のリンクを管理する。

```text
~/.config/nvim        -> nix/modules/home/assets/nvim
~/.config/nvim-vscode -> nix/modules/home/assets/nvim-vscode
```

`nvim-vscode/init.lua` は leader 設定と Cursor コマンドへのキーマップだけを所有する。通常版のモジュールを `require` せず、プラグインも読み込まない。

Cursor の `settings.json` は端末固有設定のまま維持し、Home Manager の管理対象にはしない。追加する設定は次の2項目だけとする。

```jsonc
"vscode-neovim.NVIM_APPNAME": "nvim-vscode",
"vscode-neovim.neovimExecutablePaths.darwin": "/etc/profiles/per-user/KokiAoyagi/bin/nvim"
```

## 実行フロー

1. Cursor が vscode-neovim を起動する。
2. vscode-neovim が指定された Neovim 実行ファイルを `NVIM_APPNAME=nvim-vscode` で起動する。
3. Neovim が `~/.config/nvim-vscode/init.lua` を読む。
4. `init.lua` が `require("vscode")` の API を使ってノーマルモードのキーを Cursor コマンドへ委譲する。
5. ファイル管理、検索、LSP、補完、診断表示、Editor Group 管理は Cursor が実行する。
6. Neovim はモード、モーション、オペレーター、テキスト編集のバックエンドを担当する。

## キーマップ

leader と local leader は Space にする。以下は特記がない限り Neovim ノーマルモード限定とする。

| キー | Cursor コマンド | 意図 |
|---|---|---|
| `<Space>ee` | `workbench.view.explorer` | Explorer を表示 |
| `<Space>pf` | `workbench.action.quickOpen` | ファイル名検索 |
| `<Space>ps` | `workbench.action.findInFiles` | プロジェクト全文検索 |
| `<Space>pws` | `workbench.action.findInFiles` | カーソル下の単語で全文検索 |
| `gd` | `editor.action.revealDefinition` | 定義へ移動 |
| `gR` | `editor.action.goToReferences` | 参照一覧 |
| `gi` | `editor.action.goToImplementation` | 実装へ移動 |
| `gt` | `editor.action.goToTypeDefinition` | 型定義へ移動 |
| `K` | `editor.action.showHover` | Hover 情報を表示 |
| `<Space>rn` | `editor.action.rename` | シンボル名変更 |
| `<Space>vca` | `editor.action.quickFix` | Code Action |
| `<Space>d` | `editor.action.showHover` | 現在位置の診断を表示 |
| `<C-h>` | `workbench.action.navigateLeft` | 左の Editor Group へ移動 |
| `<C-j>` | `workbench.action.navigateDown` | 下の Editor Group へ移動 |
| `<C-k>` | `workbench.action.navigateUp` | 上の Editor Group へ移動 |
| `<C-l>` | `workbench.action.navigateRight` | 右の Editor Group へ移動 |

`<Space>pws` は `vim.fn.expand("<cword>")` の結果を `workbench.action.findInFiles` の `query` 引数として渡す。

## Cursor キーバインド競合方針

現在の `keybindings.json` には、過去に追加された vscode-neovim の既定キー解除と、Neovim の Ctrl キー処理より優先される独自設定がある。

整理は次の規則に限定する。

- `command` が `-vscode-neovim.` で始まる古い解除エントリを除去し、拡張機能の既定動作を復元する。
- `Ctrl+d` など既存の独自コマンドは削除せず、`neovim.init` かつノーマルモードのときには発火しない `when` 条件へ限定する。
- ターミナル、入力欄、Composer、Notebook、検索結果、Explorer など、Neovim エディタ外のコンテキストでは既存動作を維持する。
- 変更対象は vscode-neovim と競合するエントリだけとし、無関係なキーバインド整理は行わない。

## 障害時の挙動

- Cursor 専用 `init.lua` の構文エラーやマッピングエラーは Cursor 内の Neovim 起動だけに影響し、通常版 Neovim には影響しない。
- vscode-neovim の問題は Cursor の `vscode-neovim logs` で確認する。
- 一時的な不調は `Neovim: Restart Extension` で再起動する。
- 復旧が必要な場合は vscode-neovim を無効化すれば、Cursor を通常エディタとして使える。
- `nvim-vscode` は通常版とデータ・状態・キャッシュを共有しないため、将来 Cursor 専用設定を拡張しても通常版へ波及しない。

## テスト戦略

### 自動テスト

- テスト内で偽の `vscode` Lua モジュールを提供し、Cursor 専用 `init.lua` を headless Neovim で読み込む。
- leader、モード、各キー、各 Cursor コマンドの対応を検証する。
- `<Space>pws` がカーソル下の単語を `query` として渡すことを検証する。
- Home Manager が `nvim-vscode` を `~/.config/nvim-vscode` へ配置する宣言を検証する。
- 通常版 Neovim の既存テストスイートを実行し、既存設定に回帰がないことを確認する。
- Nix 設定を評価し、Cursor の `settings.json` と `keybindings.json` を JSONC として検証する。
- Cursor CLI または拡張機能ディレクトリで vscode-neovim のインストールを確認する。

### 手動スモークテスト

Cursor を Reload Window した後、次を確認する。

- Normal、Insert、Visual のモード遷移
- ファイル検索、全文検索、カーソル下の単語検索
- 定義、参照、実装、型定義、Hover、Rename、Code Action、診断表示
- 複数 Editor Group 間の `Ctrl+h/j/k/l` 移動
- Cursor の入力欄、ターミナル、Notebook では既存ショートカットが維持されること
- 通常のターミナルから起動した Neovim が従来どおり動作すること

## 完了条件

- Cursor 内で vscode-neovim が `NVIM_APPNAME=nvim-vscode` として起動する。
- 承認済みのキーマップがノーマルモードで動作する。
- ノーマルモードでは Neovim のキー処理が競合する Cursor 設定より優先される。
- Cursor エディタ外の既存ショートカットは維持される。
- 通常版 Neovim の設定ファイルと挙動が変更されていない。
- 自動テストと手動スモークテストが完了する。
