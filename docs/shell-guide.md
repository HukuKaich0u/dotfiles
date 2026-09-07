---
created: 2026-09-05
updated: 2026-09-07
author: Koki Aoyagi
type: runbook
---

# zsh / Starship

## プロンプト

背景色の帯を使わない1行の構成。ディレクトリを青、ブランチを控えめな色、
Git の変更を黄、入力記号を緑で表示する。コマンドが失敗すると入力記号が赤になる。

```text
~/Documents/repos/personal/dotfiles main !↑ ❯
```

- パスは末尾5階層まで表示する。Git repository でも親ディレクトリを残す。
  ホームディレクトリは `~`、さらに深いパスの前方を省略する場合は `…/` で表示する。
- 長いブランチ名は先頭20文字までを残し、省略記号を付ける。
- Git の変更・未追跡ファイル・ahead/behind・rebase などの操作状態を表示する。
- 実行時間は2秒以上かかったコマンドだけに表示する。
- SSH 接続時のホスト名とバックグラウンドジョブは、該当時に表示する。
- 時刻、画面幅を埋める線、右プロンプト、言語バージョン、Kubernetes / Terraform の
  常設モジュールは置かない。

設定は `nix/modules/home/programs/starship.nix` にある。
各項目の仕様は [Starship Configuration](https://starship.rs/config/) を参照。

## 起動処理

macOS では nix-darwin の `programs.zsh.enableGlobalCompInit = false` にし、
補完の初期化を Home Manager の1回にまとめる。システムのデフォルトプロンプトも
初期化せず、Starship を使う。補完、履歴候補、syntax highlighting は維持する。

`nix/modules/home/programs/zsh-integrations.nix` が、mise / direnv / zoxide /
Starship の zsh 初期化コードを Nix のビルド時に生成する。macOS / Linux ともに
このファイルを source する。ツールのバージョンが変わると Nix が再生成するため、
手動でキャッシュを更新する必要はない。

mise の `hook-env` と direnv の `.envrc` 評価は実行時に残している。
`cd` や設定変更に応じた環境切り替えは継続する。
起動だけを速くするために mise を shims に置き換えたり、hook を無効化したりしない。
仕組みは [mise の shell activation](https://mise.jdx.dev/cli/activate.html) を参照。

## 検証

```sh
sh tests/starship_prompt_test.sh
sh tests/zsh_headless_smoke_test.sh
nix build --no-link --no-write-lock-file ./nix#darwinConfigurations.KokiAoyagi.system
```

Starship のテストは、実際の設定と一時的な Git repository で、80桁の表示幅、
親ディレクトリの表示、長いブランチ名、Git の状態、失敗時の色、実行時間、
ジョブ表示を確認する。狭い Terminal では自然に折り返す。
headless のテストはインストール済み設定に対する `zsh -lic` の完走確認。

2026-09-05 の macOS / zsh 5.9.1 / Starship 1.26.0 での検証結果:

- インストール済みの旧設定と、ビルド済みの新設定を交互に起動して比較。
  初回を除く8回の login shell 起動中央値は約266 ms → 61 ms。
  新設定は一時的な `ZDOTDIR` から読み込み、システムへの適用前に検証した値。
- `compinit` の実行回数は2回 → 1回。補完は1,734件読み込まれた。
- PTY と xterm のヘッドレスエミュレーターで幅を変えると、旧設定ではプロンプトの
  断片が残った。新設定では入力途中に24〜100桁を27回切り替えても断片が残らず、
  入力文字列が維持された。利用中の GUI Terminal 自体での確認は適用後に行う。
- mise / direnv のテスト用設定で、`cd` 時の環境変数の追加と退出時の解除を確認。
- Linux は Home Manager の評価まで確認。Linux 上での実行は未確認。

## 反映

新規 Nix ファイルを Git の追跡対象にした後、repository のルートで実行する。

```sh
sudo darwin-rebuild switch --flake ./nix#KokiAoyagi
```

その後、新しい Terminal タブを開く。`source ~/.zshrc` だけでは `/etc/zshrc` の
変更を検証できず、以前の hook も残るため、新しい shell で確認する。

通常幅から狭い幅へ何度か往復し、入力中のコマンドが欠けないことを確認する。
旧プロンプトの断片が scrollback に残っている場合は、新しいタブで確認する。
