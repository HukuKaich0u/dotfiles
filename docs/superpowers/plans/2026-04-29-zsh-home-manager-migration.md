# zsh Home Manager Migration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `zsh` の入口と設定本体を `home-manager` 管理へ移し、実体を `~/.config/zsh` に寄せつつ現挙動を維持する

**Architecture:** `programs.zsh` を新設し、`dotDir` を `~/.config/zsh` に固定する。既存 shell script は `.config/nix/home-manager/zsh/` へ移し、`.zshenv` `.zprofile` `.zshrc` は Home Manager 生成物から source する。初回は `brew shellenv`、`conda`、`gcloud`、`local.zsh` を残す。

**Tech Stack:** Nix, Home Manager, zsh, Homebrew

---

## Chunk 1: file shape

### Task 1: `zsh` の source of truth を Nix 配下へ移す

**Files:**
- Create: `.config/nix/home-manager/zsh/aliases.zsh`
- Create: `.config/nix/home-manager/zsh/completion.zsh`
- Create: `.config/nix/home-manager/zsh/env.zsh`
- Create: `.config/nix/home-manager/zsh/homebrew.zsh`
- Create: `.config/nix/home-manager/zsh/plugins.zsh`
- Check: `.config/zsh/.zshrc`
- Check: `.config/zsh/.zprofile`
- Check: `.config/zsh/env.zsh`
- Check: `.config/zsh/aliases.zsh`
- Check: `.config/zsh/completion.zsh`
- Check: `.config/zsh/homebrew.zsh`
- Check: `.config/zsh/plugins.zsh`

- [ ] Step 1: 既存 `zsh` 設定の tracked 部分だけ確認
Run: `find .config/zsh -maxdepth 1 -type f | sort`
Expected: state file と設定 file を分離して把握

- [ ] Step 2: `env` `aliases` `completion` `plugins` `homebrew` を Nix 配下へ移す
Expected: runtime source of truth が `.config/nix/home-manager/zsh/` 側になる

- [ ] Step 3: `.zcompdump` `.zsh_history` は移さない
Expected: state file は設定管理から外れたまま

## Chunk 2: home-manager wiring

### Task 2: `programs.zsh` を追加する

**Files:**
- Create: `.config/nix/home-manager/zsh.nix`
- Modify: `.config/nix/home-manager/home.nix`

- [ ] Step 1: `home.nix` に `./zsh.nix` を import
Expected: `git` `tmux` と同列に `zsh` module を読む

- [ ] Step 2: `xdg.enable = true` を入れる
Expected: `config.xdg.configHome` と `config.xdg.stateHome` を使える

- [ ] Step 3: `programs.zsh.enable = true` と `programs.zsh.dotDir = "${config.xdg.configHome}/zsh"` を追加
Expected: `~/.zshenv` は Home Manager 生成、実体は `~/.config/zsh`

- [ ] Step 4: `envExtra` `profileExtra` `initExtra` で Nix 配下の分割 file を source
Expected: 既存挙動を保ったまま entrypoint だけ差し替わる

- [ ] Step 5: `enableCompletion` と history path を現行値へ合わせる
Expected: 補完と `~/.local/state/zsh/.zsh_history` が維持される

## Chunk 3: cleanup

### Task 3: 旧 dotfile 経路を止める

**Files:**
- Modify: `install.sh`
- Delete: `.zshenv`
- Delete: `.zprofile`
- Delete: `.zshrc`
- Check: `.config/zsh/`

- [ ] Step 1: `install.sh` から `.zshenv` `.zprofile` `.zshrc` の link 対象を外す
Expected: shell 入口の責務が `home-manager` に移る

- [ ] Step 2: `install.sh` が `.config/zsh` を runtime source として配らない形にする
Expected: shell 設定の配布経路が二重にならない

- [ ] Step 3: repo root の旧入口 file を削除
Expected: 手書き entrypoint が消える

- [ ] Step 4: 旧 `.config/zsh` の tracked 設定 file を整理
Expected: runtime と repo 内 source of truth が混ざらない

## Chunk 4: verification

### Task 4: 衝突を避けて切り替えを確認する

**Files:**
- Check: `.config/nix/home-manager/zsh.nix`
- Check: `install.sh`
- Check: `.config/nix/flake.nix`

- [ ] Step 1: 既存 `~/.zshenv` `~/.zprofile` `~/.zshrc` `~/.config/zsh` との衝突条件を確認
Run: `ls -ld ~/.zshenv ~/.zprofile ~/.zshrc ~/.config/zsh`
Expected: unlink / backup が必要か判断できる

- [ ] Step 2: Nix 評価確認
Run: `home-manager build --flake .config/nix#KokiAoyagi`
Expected: PASS

- [ ] Step 3: 実適用
Run: `home-manager switch --flake .config/nix#KokiAoyagi`
Expected: `~/.zshenv` と `~/.config/zsh/*` が Home Manager 管理へ切替

- [ ] Step 4: shell runtime 確認
Run: `zsh -lic 'printf "ZDOTDIR=%s\nHISTFILE=%s\n" "$ZDOTDIR" "$HISTFILE"'`
Expected: `ZDOTDIR=$HOME/.config/zsh` と `HISTFILE=$HOME/.local/state/zsh/.zsh_history`

- [ ] Step 5: 既存機能確認
Run: `zsh -lic 'alias nv >/dev/null && command -v brew && command -v starship'`
Expected: alias, brew, prompt 依存が解決

- [ ] Step 6: commit
```bash
git add .config/nix/home-manager/home.nix .config/nix/home-manager/zsh.nix .config/nix/home-manager/zsh install.sh .zshenv .zprofile .zshrc .config/zsh
git commit -m "feat(zsh): manage shell with home-manager"
```

## Unresolved Questions

- なし
