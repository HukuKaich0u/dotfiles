# tmux Nix Migration 設計

**Goal:** `tmux` の本体設定、plugin の取得と読み込み、関連 package の管理を `home-manager` に集約し、TPM 依存をなくしつつ現在の挙動を維持する。

## スコープ

この設計は、既存の `tmux` 設定を `home-manager` 配下へ移行するためのもの。

含むもの:
- `programs.tmux` による `tmux` 管理
- TPM の撤去
- 現在使っている plugin 群の Home Manager 管理への移行
- 既存 `tmux.conf` 本文を別ファイルのまま保持し、`home.nix` から `extraConfig` として読み込む構成
- plugin path 直参照箇所の修正

含まないもの:
- keybind や status line の大幅な見直し
- plugin の削除や代替 plugin への置き換え
- `tmux` 以外の dotfiles の Nix 移行

## 選択肢

### Option 1: `programs.tmux` + `extraConfig = builtins.readFile ...`

`home-manager` の `programs.tmux` を使って plugin を宣言管理し、既存の `tmux.conf` 本文は別ファイルとして残して `extraConfig` で読み込む。

Pros:
- 既存挙動を最も保ちやすい
- TPM を外しつつ責務を `home-manager` に寄せられる
- 長い `tmux` 設定を `home.nix` に直書きせずに済む

Cons:
- 一部の設定は依然として `tmux.conf` 形式のまま残る
- plugin path を前提にした行は調整が必要

### Option 2: `home.file` で `tmux.conf` を配布し、plugin だけ Nix 管理

`tmux.conf` はそのまま home 配下へ配布し、plugin の取得だけ Home Manager で管理する。

Pros:
- 既存ファイル構成の変更が少ない

Cons:
- `tmux` 設定本体と plugin 管理の責務が分散する
- `programs.tmux` の統合管理を活かせない

### Option 3: `programs.tmux` の各 option へ全面分解

keybind や各種 option を Nix 式へ細かく分解し、`extraConfig` を極小化する。

Pros:
- 宣言的には最も一貫する

Cons:
- 変換コストが高い
- 現状維持に対する回帰リスクが高い
- plugin 固有設定まで含めると可読性がむしろ下がりうる

## 推奨案

Option 1 を採用する。

目的は「完全に Nix 管理へ寄せること」と「現在の挙動維持」の両立であり、そのためには `programs.tmux` で本体と plugin 管理を持ちながら、既存の詳細設定は `extraConfig` で流し込む形が最も安定する。TPM をやめても plugin の取得と読み込みは Home Manager が担えるため、責務は十分に Nix 側へ寄る。

## 構成設計

### `home.nix`

- `programs.tmux.enable = true` を追加する
- 必要に応じて `terminal = "tmux-256color"` などの基本 option を `programs.tmux` 側で持つ
- plugin 群を `programs.tmux.plugins` で宣言する
- `extraConfig = builtins.readFile ./tmux/tmux.conf;` のように別ファイルを読み込む

### `tmux.conf` 相当ファイル

- 既存 `tmux.conf` の本文をほぼそのまま保持する
- keybind、status、pane/window 設定、plugin 固有設定値はこのファイルに残す
- TPM bootstrap 行は削除する
- TPM 専用の environment 変数設定は削除する

### plugin 管理

対象 plugin は現行構成をそのまま移す。

- `catppuccin/tmux`
- `omerxx/tmux-sessionx`
- `tmux-plugins/tmux-resurrect`
- `tmux-plugins/tmux-continuum`
- `tmux-plugins/tmux-battery`
- `tmux-plugins/tmux-online-status`

`tpm` 自体は移行対象ではなく削除する。

## 移行時の注意点

### TPM 依存行の除去

次は不要になる。

- `run '~/.config/tmux/plugins/tpm/tpm'`
- `TMUX_PLUGIN_MANAGER_PATH` の設定

### plugin path 直参照の修正

現在の設定には `tmux-resurrect` の `save.sh` を `~/.config/tmux/plugins/...` 経由で呼ぶ hook がある。Nix 管理後は plugin 実体の配置が変わるため、この参照は Home Manager 管理後も成立する形に書き換える必要がある。

ここは実装上の主要リスクなので、移行後に `session-renamed` hook が正しく動くかを重点確認する。

### plugin 設定値の維持

以下のような plugin 設定値は `extraConfig` に残してよい。

- `@sessionx-*`
- `@resurrect-*`
- `@continuum-*`
- `@catppuccin_*`
- `@online_*`

## 実装単位

1. `home.nix` に `programs.tmux` を追加する
2. 既存の `tmux.conf` 本文を、Nix から読む専用の別ファイルへ移す
3. TPM 依存行を削除する
4. plugin 群を Home Manager の plugin 宣言へ移す
5. `resurrect` hook の script 呼び出しを Nix 管理後の plugin path に合わせて修正する
6. runtime で未使用になる旧 `tmux.conf` の扱いを整理する

## テスト方針

`home-manager` 適用後に手動確認する。

1. `home-manager` の build / switch が通る
2. `tmux` 起動時に plugin 関連エラーが出ない
3. status line の表示が崩れない
4. `sessionx` が起動する
5. `resurrect` / `continuum` の保存・復元が動く
6. pane 操作、copy mode、mouse scroll が従来どおり動く

## リスク

- Home Manager 側の `tmux` plugin 提供名と現在の plugin 名が 1 対 1 で対応しない可能性がある
- plugin path を仮定した hook 修正を誤ると、保存・復元だけ静かに壊れる可能性がある
- plugin の読み込み順が変わると、theme や status line の見え方が微妙に変わる可能性がある

## 成功条件

- TPM を使わずに `tmux` と全 plugin が Home Manager 配下で有効化される
- 現在使っている plugin 機能がすべて維持される
- 設定本文は `home.nix` にベタ書きせず、別ファイルとして保持される
