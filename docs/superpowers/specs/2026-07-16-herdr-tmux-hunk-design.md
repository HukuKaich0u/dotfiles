# Herdr tmux ライク設定と Hunk 連携設計

## 目的

Herdr を tmux の外側で日常的に使えるようにし、既存の tmux と同じ prefix と操作体系を持たせる。Herdr 固有の workspace、agent sidebar、通知機能はその役割に合わせて設定し、差分レビューには Hunk を一時 pane として統合する。

設定とパッケージの所有元を dotfiles に集約し、別環境でも Nix または nix-darwin の適用によって再現できる構成にする。

## スコープ

この変更は次を対象とする。

- Herdr の `config.toml` を Home Manager 管理へ移す
- tmux と対応する Herdr キーバインドを設定する
- Herdr の terminal theme、sidebar、通知、通知音を設定する
- Hunk を公式 Nix flake と Home Manager module で導入する
- Herdr のカスタムコマンドから Hunk を起動する
- Herdr キーバインドのリポジトリ内ドキュメントを追加する
- Nix、TOML、宣言内容を検証する自動テストを追加する

次は対象外とする。

- Herdr 本体の Homebrew から Nix への移行
- Hunk を Git または Jujutsu の標準 pager にする変更
- Hunk agent skill の導入
- Herdr plugin の導入
- tmux 設定そのものの変更
- Herdr に存在しない tab 並べ替え機能の再現

## 採用方式

### Herdr

Herdr 本体は現状どおり nix-darwin の `homebrew.brews` から Homebrew formula を管理する。設定だけを Home Manager に移し、`~/.config/herdr/config.toml` を宣言的に配置する。

現在の `config.toml` は通常ファイルであるため、`xdg.configFile."herdr/config.toml".force = true` を使って Home Manager 管理へ切り替える。現在の `onboarding = false` と `experimental.pane_history = false` は新設定へ引き継ぐ。

### Hunk

Hunk は Homebrew ではなく、公式 flake と公式 Home Manager module を使う。`nix/flake.nix` に `github:modem-dev/hunk` を追加し、Hunk 側の `nixpkgs` input はこの dotfiles の `nixpkgs` に follow させる。Hunk の revision は `nix/flake.lock` で固定する。

standalone Home Manager と nix-darwin 経由の Home Manager の両方から Hunk input を参照できるように引数を渡し、共通 Home Manager module で `inputs.hunk.homeManagerModules.default` 相当を import する。

`programs.hunk.enable = true` で package と設定を管理する。`enableGitIntegration` は無効のままとし、既存の Git pager は変更しない。

## ファイルと責務

```text
nix/
├── flake.nix
├── flake.lock
└── modules/
    ├── darwin/
    │   └── homebrew.nix                 # Herdr 本体。Hunk は追加しない
    └── home/
        ├── default.nix                  # Herdr module と Hunk module を import
        ├── assets/
        │   └── herdr/
        │       ├── config.toml          # Herdr の実設定
        │       └── key-bind.md          # リポジトリ内だけのキー一覧
        └── programs/
            ├── herdr.nix                # config.toml だけを xdg.configFile へ配置
            └── hunk.nix                 # 公式 module の programs.hunk 設定
```

`key-bind.md` は Home Manager の配置対象に含めず、`~/.config/herdr/` には作らない。

## 概念の対応

日常操作では次の対応として扱う。

| tmux | Herdr | 用途 |
|---|---|---|
| session | workspace | repo、task、調査単位の切り替え |
| window | tab | workspace 内の画面切り替え |
| pane | pane | 分割ターミナル |
| tmux server/socket | Herdr session | 完全に分離された永続実行環境 |

Herdr の named session は workspace の代わりに常用せず、完全に別の pane、socket、永続状態が必要な場合だけ使う。

## Herdr キーバインド

### tmux と対応する操作

| キー | Herdr 操作 | tmux 側の意味 |
|---|---|---|
| `Ctrl-g` | prefix | prefix |
| `prefix+c` | tab 作成 | window 作成 |
| `prefix+p` / `prefix+n` | 前後の tab | 前後の window |
| `prefix+1..9` | 番号で tab へ移動 | 番号で window へ移動 |
| `prefix+comma` | tab 名変更 | window 名変更 |
| `prefix+ampersand` | tab を閉じる | window を閉じる |
| `prefix+h/j/k/l` | pane focus | pane focus |
| `prefix+shift+j` | 下に pane 分割 | `J` で下に分割 |
| `prefix+shift+l` | 右に pane 分割 | `L` で右に分割 |
| `prefix+[` | copy mode | copy mode |
| `prefix+z` | pane zoom | pane zoom |
| `prefix+x` | pane を閉じる | pane を閉じる |
| `prefix+s` | resize mode | resize mode |
| `prefix+r` | 設定再読み込み | 設定再読み込み |
| `prefix+d` | detach | detach |
| `prefix+;` | 最後に focus した pane | last pane |
| `prefix+o` | workspace picker | tmux-sessionx |
| `prefix+shift+9` / `prefix+shift+0` | 前後の workspace | 前後の session |
| `prefix+shift+4` | workspace 名変更 | session 名変更 |

### Herdr 固有操作

| キー | 操作 |
|---|---|
| `prefix+shift+n` | workspace 作成 |
| `prefix+shift+g` | worktree 作成 |
| `prefix+shift+d` | workspace を閉じる |
| `prefix+g` | Herdr navigator |
| `prefix+b` | sidebar 切り替え |
| `prefix+shift+s` | settings |
| `prefix+shift+o` | 通知対象へ移動 |
| `prefix+?` | keybinding help |
| `prefix+shift+h` | Hunk を一時 pane で起動 |

Hunk は次のカスタムコマンドとして起動する。

```toml
[[keys.command]]
key = "prefix+shift+h"
type = "pane"
command = "hunk diff --watch"
description = "review changes with Hunk"
```

Herdr はこの command を focus 中 pane の cwd から実行する。Hunk 終了時には一時 pane も閉じる。

### 意図的に割り当てない操作

- `H` と `K` の pane 分割は割り当てない。Herdr の分割方向は右と下だけであり、利用者もその2方向だけを必要としている。
- tmux の `<` と `>` に相当する tab 並べ替えは、Herdr に対応する操作がないため再現しない。
- `swap_pane_left/down/up/right` はすべて空にする。`shift+j` と `shift+l` を分割へ、`shift+h` を Hunk へ使い、`shift+k` だけに予期しない swap を残さない。

## Herdr の外観と動作

### Theme

```toml
[theme]
name = "terminal"
```

Herdr 固有の固定 palette ではなく、Ghostty または WezTerm の ANSI palette に追従させる。

### Terminal

```toml
[terminal]
new_cwd = "follow"
```

新しい pane、tab、workspace は、明示的な cwd 指定がない場合に focus 中 pane または workspace の cwd を引き継ぐ。

### Sidebar と pane

```toml
[ui]
sidebar_width = 30
sidebar_min_width = 18
sidebar_max_width = 36
sidebar_collapsed_mode = "compact"
mouse_capture = true
confirm_close = true
prompt_new_tab_name = true
pane_borders = true
pane_gaps = true
show_agent_labels_on_pane_borders = true
hide_tab_bar_when_single_tab = true
agent_panel_sort = "priority"
```

`priority` は agent の表示フィルターではなく並び順である。Idle を含む全 agent を `blocked`、`done`、`working`、`idle`、`unknown` の順に表示する。sidebar を閉じた場合も細い status rail を残す。

### 通知

```toml
[ui.toast]
delivery = "system"
delay_seconds = 1

[ui.sound]
enabled = true
```

macOS では導入済みの `terminal-notifier` を利用できる。agent が background workspace で完了または入力待ちになった際に system notification と通知音を出す。

### 永続履歴

```toml
[experimental]
pane_history = false
```

pane 内容には prompt、token、command output などが含まれ得るため、full server restart をまたぐ画面内容の保存は引き続き無効にする。

## Hunk 設定

公式 Home Manager module の `programs.hunk.settings` で次を生成する。

```toml
theme = "auto"
mode = "auto"
exclude_untracked = false
line_numbers = true
wrap_lines = false
menu_bar = true
transparent_background = true
```

- `theme = "auto"` は起動時に terminal background を問い合わせて明暗を選ぶ。
- `mode = "auto"` は利用可能なサイズに応じて split と stack を切り替える。
- untracked file も working tree review に含める。
- watch は全 Hunk 起動の既定にはせず、Herdr の custom command にだけ `--watch` を付ける。
- agent note と Hunk skill の連携は初回変更に含めない。

## リポジトリ内キードキュメント

`nix/modules/home/assets/herdr/key-bind.md` には次を記載する。

- prefix が `Ctrl-g` であること
- tmux と対応する key、Herdr 操作、tmux 側の意味
- Herdr 固有 key
- Hunk 起動 key と起動内容
- `H/K` 分割、tab 並べ替え、pane swap を割り当てない理由
- workspace、tab、pane、session の概念対応

`config.toml` と `key-bind.md` の key 一覧をテストで照合し、片方だけが変更される drift を防ぐ。

## 適用と移行

1. flake input と Home Manager module の配線を追加する。
2. Herdr asset、Herdr module、Hunk module、key document を追加する。
3. 自動テストと Nix 評価を通す。
4. nix-darwin を適用し、現在の Herdr config を Home Manager 管理へ切り替える。
5. 実行中 Herdr server に `herdr server reload-config` を送る。
6. `prefix+?` と Hunk 起動を手動確認する。

設定移行後も既存 pane と agent process は維持する。startup-only setting の確認が必要な場合だけ、利用者の許可を得て Herdr server を再起動する。

## 障害時の挙動

- Home Manager が既存 Herdr config を所有できない場合は、`force = true` の宣言と activation output を確認する。
- Herdr が不正な key または重複 key を検出した場合、その binding は無効化されて diagnostic が記録される。reload 後に警告が残る状態を完了としない。
- Hunk flake または module が現在の nixpkgs と評価できない場合は、Homebrew へ暗黙に切り替えず、input revision と module interface を確認する。
- Hunk が起動できない場合も Herdr の通常 pane は影響を受けない。custom command pane が終了するだけである。
- 適用後に問題がある場合は Home Manager または nix-darwin の前 generation へ戻せる。

## テスト戦略

### 自動テスト

- `builtins.fromTOML` で Herdr `config.toml` の構文を検証する。
- Herdr module が共通 Home Manager module から import されていることを検証する。
- Hunk input が nixpkgs を follow し、standalone Home Manager と nix-darwin Home Manager の両方へ渡されていることを検証する。
- Hunk 公式 Home Manager module が import され、`programs.hunk.enable = true` であることを検証する。
- Hunk が `homebrew.brews` に追加されていないことを検証する。
- Herdr の prefix、tab、workspace、pane、分割、copy、resize、reload、detach、Hunk key を検証する。
- pane swap がすべて無効であることを検証する。
- theme、sidebar、agent sort、notification、sound、pane history を検証する。
- `key-bind.md` の主要 key と `config.toml` の対応を検証する。
- Home Manager が `key-bind.md` を `~/.config/herdr/` へ配置しないことを検証する。
- `nix flake check ./nix` を実行する。

### 手動スモークテスト

nix-darwin 適用と Herdr config reload 後に次を確認する。

- `Ctrl-g` が prefix として動作する。
- `c`、`p/n`、`1..9` で tab を操作できる。
- `o`、`Shift+9/0` で workspace を移動できる。
- `h/j/k/l` で pane focus を移動できる。
- `J` で下、`L` で右に pane を分割できる。
- `[` で copy mode、`s` で resize mode、`z` で zoom に入れる。
- `r` で config を再読み込みし、`d` で detach できる。
- sidebar に Idle を含む agent が priority 順で表示される。
- sidebar collapse 後に compact rail が残る。
- pane border に agent label が表示される。
- background agent の完了または入力待ちで macOS notification と音が出る。
- `Shift+h` で focus 中 pane の cwd を対象に Hunk が起動し、変更が watch 更新される。
- Hunk 終了時に一時 pane が閉じる。
- `git diff` の既存 pager が変わっていない。

## 完了条件

- Herdr 本体は Homebrew、Herdr config は Home Manager という所有境界が明確である。
- Hunk package と config が公式 Nix/Home Manager integration で管理される。
- 承認済みの tmux ライク keybinding が有効で、競合 diagnostic がない。
- Terminal theme、Balanced sidebar、system notification、通知音が設計どおり動作する。
- Hunk を Herdr から一時 pane として起動できる。
- `key-bind.md` がリポジトリ内にあり、ローカル config directory には配置されない。
- 自動テストと手動スモークテストが完了する。
