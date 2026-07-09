#!/bin/sh

# 回帰テスト: pty なし (headless) で zsh の login + interactive 起動が完走するか。
#
# nixpkgs の zsh 5.9 には、コマンド置換 $( ) の子プロセスが速く終了すると
# SIGCHLD を取り逃して waitforpid で永久にハングするバグがあった (2026-07 に遭遇、
# zsh 5.9.1 で修正)。Cursor / VSCode は pty なしで `zsh -lic '...'` の環境解決
# プローブを走らせるため、このバグを踏むとターミナルが一切開けなくなる。
# ここでは実際にインストール済みの zsh を pty なしで起動し、制限時間内に
# 終了することを確認する。

set -eu

# home-manager が入れる zsh を優先し、なければ PATH 上の zsh で確認する。
zsh_bin="/etc/profiles/per-user/$(id -un)/bin/zsh"
if [ ! -x "$zsh_bin" ]; then
    zsh_bin="$(command -v zsh || true)"
fi
if [ -z "$zsh_bin" ] || [ ! -x "$zsh_bin" ]; then
    echo "SKIP: zsh not found"
    exit 0
fi

# Cursor / VSCode の環境解決プローブと同じ形 (-lic, stdin は /dev/null)。
"$zsh_bin" -lic 'exit 0' </dev/null >/dev/null 2>&1 &
pid=$!

i=0
while kill -0 "$pid" 2>/dev/null; do
    i=$((i + 1))
    if [ "$i" -ge 150 ]; then
        kill -9 "$pid" 2>/dev/null || true
        echo "FAIL: headless '$zsh_bin -lic' が 15 秒以内に終了しない (SIGCHLD 取り逃しバグの疑い)" >&2
        exit 1
    fi
    sleep 0.1
done

if ! wait "$pid"; then
    echo "FAIL: headless '$zsh_bin -lic' が非ゼロ終了した" >&2
    exit 1
fi

echo "OK: headless zsh -lic completed ($zsh_bin)"
