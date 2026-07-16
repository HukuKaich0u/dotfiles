# Herdr tmux ライク設定と Hunk 連携 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Herdr を tmux と同じ操作体系・Terminal theme・Balanced sidebar・macOS通知で Home Manager 管理し、公式 Nix package の Hunk を `prefix+Shift+h` から一時 pane として起動できるようにする。

**Architecture:** Herdr 本体は既存どおり nix-darwin 経由の Homebrew 管理を維持し、`config.toml` だけを Home Manager が所有する。Hunk は公式 flake input と公式 Home Manager moduleで package と設定を管理し、Herdr の `type = "pane"` custom command から focus 中 pane の cwd で実行する。リポジトリ内の `key-bind.md` は設定の隣に置くが、Home Manager の配置対象には含めない。

**Tech Stack:** Nix flakes、nix-darwin、Home Manager、TOML、POSIX shell tests、Herdr 0.7.3、Hunk公式flake

---

## ファイル構成

### 作成

- `nix/modules/home/programs/hunk.nix`: Hunk公式Home Manager moduleの設定値
- `nix/modules/home/programs/herdr.nix`: Herdr `config.toml` だけをXDG configへ配置
- `nix/modules/home/assets/herdr/config.toml`: Herdrの実設定
- `nix/modules/home/assets/herdr/key-bind.md`: リポジトリ内だけのキーバインド資料
- `tests/herdr_hunk_management_test.sh`: package ownership、flake配線、設定、ドキュメントの回帰テスト

### 変更

- `nix/flake.nix`: Hunk input、standalone Home Managerとnix-darwinへの引数配線
- `nix/flake.lock`: Hunk input revisionの固定
- `nix/modules/darwin/home-manager.nix`: Hunk inputをdarwin配下のHome Managerへ渡す
- `nix/modules/home/default.nix`: Hunk公式module、Hunk設定module、Herdr設定moduleのimport

### 変更しない

- `nix/modules/darwin/homebrew.nix`: Herdr本体の所有を維持し、Hunkは追加しない
- `nix/modules/home/programs/git.nix`: HunkをGit標準pagerにしない
- `nix/modules/home/assets/tmux/tmux.conf`: tmux側の設定は変更しない

---

### Task 1: Hunkを公式flakeとHome Manager moduleで管理する

**Files:**
- Create: `tests/herdr_hunk_management_test.sh`
- Create: `nix/modules/home/programs/hunk.nix`
- Modify: `nix/flake.nix`
- Modify: `nix/flake.lock`
- Modify: `nix/modules/darwin/home-manager.nix`
- Modify: `nix/modules/home/default.nix`
- Verify unchanged: `nix/modules/darwin/homebrew.nix`

- [ ] **Step 1: Hunkの所有とflake配線を表す失敗テストを書く**

`tests/herdr_hunk_management_test.sh` を次の内容で作成する。

```sh
#!/bin/sh

set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
flake_nix="$repo_root/nix/flake.nix"
home_default_nix="$repo_root/nix/modules/home/default.nix"
darwin_home_manager_nix="$repo_root/nix/modules/darwin/home-manager.nix"
homebrew_nix="$repo_root/nix/modules/darwin/homebrew.nix"
hunk_nix="$repo_root/nix/modules/home/programs/hunk.nix"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"

  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_not_contains() {
  file="$1"
  needle="$2"
  message="$3"

  if grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$flake_nix" 'hunk = {' \
  "flake.nix should declare the Hunk input"
assert_contains "$flake_nix" 'url = "github:modem-dev/hunk";' \
  "the Hunk input should use the official repository"
if ! sed -n '/hunk = {/,/};/p' "$flake_nix" | \
  grep -Fq 'inputs.nixpkgs.follows = "nixpkgs";'; then
  echo "the Hunk input should follow the shared nixpkgs revision"
  exit 1
fi
assert_contains "$flake_nix" 'extraSpecialArgs = {inherit hunk;};' \
  "standalone Home Manager should receive the Hunk input"
assert_contains "$flake_nix" 'specialArgs = {inherit self hunk;};' \
  "nix-darwin modules should receive the Hunk input"
assert_contains "$darwin_home_manager_nix" 'home-manager.extraSpecialArgs = {inherit hunk;};' \
  "darwin Home Manager should receive the Hunk input"

assert_contains "$home_default_nix" 'hunk.homeManagerModules.default' \
  "the shared Home Manager tree should import Hunk's official module"
assert_contains "$home_default_nix" './programs/hunk.nix' \
  "the shared Home Manager tree should import the local Hunk settings"

if [ ! -f "$hunk_nix" ]; then
  echo "programs/hunk.nix should exist"
  exit 1
fi

assert_contains "$hunk_nix" 'programs.hunk = {' \
  "hunk.nix should configure programs.hunk"
assert_contains "$hunk_nix" 'enable = true;' \
  "Home Manager should install Hunk"
assert_contains "$hunk_nix" 'enableGitIntegration = false;' \
  "Hunk should not replace the existing Git pager"
assert_contains "$hunk_nix" 'theme = "auto";' \
  "Hunk should select a theme from the terminal background"
assert_contains "$hunk_nix" 'mode = "auto";' \
  "Hunk should choose split or stack layout automatically"
assert_contains "$hunk_nix" 'exclude_untracked = false;' \
  "Hunk should include untracked files"
assert_contains "$hunk_nix" 'line_numbers = true;' \
  "Hunk should show line numbers"
assert_contains "$hunk_nix" 'wrap_lines = false;' \
  "Hunk should keep long diff lines unwrapped"
assert_contains "$hunk_nix" 'menu_bar = true;' \
  "Hunk should keep its menu bar visible"
assert_contains "$hunk_nix" 'transparent_background = true;' \
  "Hunk should preserve terminal transparency"

assert_not_contains "$homebrew_nix" '"hunk"' \
  "Homebrew must not own Hunk when the official Nix module is used"

echo "Herdr and Hunk management tests passed"
```

- [ ] **Step 2: テストを実行してHunk未配線で失敗することを確認する**

Run:

```sh
sh tests/herdr_hunk_management_test.sh
```

Expected: `flake.nix should declare the Hunk input` でFAILする。

- [ ] **Step 3: Hunk inputと両Home Manager経路への引数配線を追加する**

`nix/flake.nix` の `inputs` に次を追加する。

```nix
hunk = {
  url = "github:modem-dev/hunk";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

`outputs` の引数に `hunk` を追加する。

```nix
outputs = {
  self,
  nixpkgs,
  home-manager,
  nix-darwin,
  hunk,
  ...
}:
```

standalone Home Managerへinputを渡す。

```nix
homeConfigurations."kokiaoyagi" = home-manager.lib.homeManagerConfiguration {
  pkgs = mkPkgs "aarch64-linux";
  extraSpecialArgs = {inherit hunk;};
  modules = [
    ./modules/home/default.nix
    ./modules/linux/default.nix
  ];
};
```

nix-darwin moduleへinputを渡す。

```nix
darwinConfigurations."KokiAoyagi" = nix-darwin.lib.darwinSystem {
  system = "aarch64-darwin";
  specialArgs = {inherit self hunk;};
  modules = [
    ./modules/darwin/system.nix
    home-manager.darwinModules.home-manager
  ];
};
```

`nix/modules/darwin/home-manager.nix` の引数と設定を次へ変更する。

```nix
{hunk, ...}: {
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.extraSpecialArgs = {inherit hunk;};
  home-manager.users."KokiAoyagi" = ./default.nix;
}
```

- [ ] **Step 4: Hunk公式moduleとローカル設定moduleをHome Managerへimportする**

`nix/modules/home/default.nix` の引数へ `hunk` を追加し、importsの先頭付近へ公式module、programs群へローカルmoduleを追加する。

```nix
{
  hunk,
  ...
}: {
  imports = [
    hunk.homeManagerModules.default
    ./packages.nix
    ./programs/agent-skills
    ./programs/bacon.nix
    ./programs/claude
    ./programs/codex
    ./programs/direnv.nix
    ./programs/git.nix
    ./programs/gh.nix
    ./programs/ghostty.nix
    ./programs/hunk.nix
    ./programs/mise.nix
    ./programs/nvim.nix
    ./programs/starship.nix
    ./programs/tmux.nix
    ./programs/yazi.nix
    ./programs/zoxide.nix
  ];
```

このblockより後ろにある既存の `home.stateVersion`、`home.sessionVariables`、`programs.home-manager.enable` は変更しない。

- [ ] **Step 5: Hunk設定moduleを作成する**

`nix/modules/home/programs/hunk.nix` を次の内容で作成する。

```nix
{
  programs.hunk = {
    enable = true;
    enableGitIntegration = false;
    settings = {
      theme = "auto";
      mode = "auto";
      exclude_untracked = false;
      line_numbers = true;
      wrap_lines = false;
      menu_bar = true;
      transparent_background = true;
    };
  };
}
```

- [ ] **Step 6: Hunk revisionだけを新規lock entryとして追加する**

Run:

```sh
nix flake lock ./nix
```

Expected: `nix/flake.lock` のroot inputsに `hunk` が追加され、Hunkとその固有inputsがlockされる。既存の `nixpkgs`、`nix-darwin`、`home-manager` entryを意図せず削除しない。

- [ ] **Step 7: Hunk管理テストとNix評価を通す**

Run:

```sh
sh tests/herdr_hunk_management_test.sh
nix eval ./nix#homeConfigurations.kokiaoyagi.activationPackage.drvPath
nix eval ./nix#darwinConfigurations.KokiAoyagi.system.drvPath
```

Expected: shell testが `Herdr and Hunk management tests passed` を出し、両 `nix eval` がderivation pathを出してexit 0になる。

- [ ] **Step 8: Hunk管理をコミットする**

```sh
git add tests/herdr_hunk_management_test.sh nix/flake.nix nix/flake.lock nix/modules/darwin/home-manager.nix nix/modules/home/default.nix nix/modules/home/programs/hunk.nix
git commit -m "feat(hunk): manage Hunk through Home Manager"
```

---

### Task 2: Herdr設定をHome Manager管理へ移す

**Files:**
- Modify: `tests/herdr_hunk_management_test.sh`
- Create: `nix/modules/home/programs/herdr.nix`
- Create: `nix/modules/home/assets/herdr/config.toml`
- Modify: `nix/modules/home/default.nix`

- [ ] **Step 1: Herdr config所有・キー・UIを表す失敗テストを追加する**

`tests/herdr_hunk_management_test.sh` の変数へ次を追加する。

```sh
herdr_nix="$repo_root/nix/modules/home/programs/herdr.nix"
herdr_config="$repo_root/nix/modules/home/assets/herdr/config.toml"
```

最後の成功メッセージの直前へ次を追加する。

```sh
assert_contains "$home_default_nix" './programs/herdr.nix' \
  "the shared Home Manager tree should import programs/herdr.nix"

if [ ! -f "$herdr_nix" ]; then
  echo "programs/herdr.nix should exist"
  exit 1
fi

if [ ! -f "$herdr_config" ]; then
  echo "assets/herdr/config.toml should exist"
  exit 1
fi

assert_contains "$herdr_nix" 'xdg.configFile."herdr/config.toml" = {' \
  "Home Manager should own Herdr config.toml"
assert_contains "$herdr_nix" 'source = ../assets/herdr/config.toml;' \
  "Home Manager should source the Herdr config asset"
assert_contains "$herdr_nix" 'force = true;' \
  "Home Manager should replace the existing unmanaged Herdr config"

assert_contains "$herdr_config" 'name = "terminal"' \
  "Herdr should use the terminal palette"
assert_contains "$herdr_config" 'new_cwd = "follow"' \
  "new Herdr panes should follow the focused cwd"
assert_contains "$herdr_config" 'prefix = "ctrl+g"' \
  "Herdr should use the tmux prefix"
assert_contains "$herdr_config" 'help = "prefix+?"' \
  "Herdr help should stay available from prefix+?"
assert_contains "$herdr_config" 'settings = "prefix+shift+s"' \
  "Herdr settings should move away from tmux resize mode"
assert_contains "$herdr_config" 'workspace_picker = "prefix+o"' \
  "Herdr workspace picker should match tmux-sessionx"
assert_contains "$herdr_config" 'goto = "prefix+g"' \
  "Herdr navigator should remain available"
assert_contains "$herdr_config" 'new_workspace = "prefix+shift+n"' \
  "Herdr should expose workspace creation"
assert_contains "$herdr_config" 'new_worktree = "prefix+shift+g"' \
  "Herdr should expose worktree creation"
assert_contains "$herdr_config" 'rename_workspace = "prefix+shift+4"' \
  "workspace rename should match tmux session rename"
assert_contains "$herdr_config" 'close_workspace = "prefix+shift+d"' \
  "Herdr should expose workspace close"
assert_contains "$herdr_config" 'previous_workspace = "prefix+shift+9"' \
  "previous workspace should match tmux previous session"
assert_contains "$herdr_config" 'next_workspace = "prefix+shift+0"' \
  "next workspace should match tmux next session"
assert_contains "$herdr_config" 'new_tab = "prefix+c"' \
  "new Herdr tab should match tmux new window"
assert_contains "$herdr_config" 'rename_tab = "prefix+comma"' \
  "Herdr tab rename should match tmux window rename"
assert_contains "$herdr_config" 'previous_tab = "prefix+p"' \
  "previous Herdr tab should match tmux previous window"
assert_contains "$herdr_config" 'next_tab = "prefix+n"' \
  "next Herdr tab should match tmux next window"
assert_contains "$herdr_config" 'switch_tab = "prefix+1..9"' \
  "Herdr tab indexes should match tmux window indexes"
assert_contains "$herdr_config" 'close_tab = "prefix+ampersand"' \
  "Herdr tab close should match tmux window close"
assert_contains "$herdr_config" 'copy_mode = "prefix+["' \
  "Herdr copy mode should match tmux copy mode"
assert_contains "$herdr_config" 'focus_pane_left = "prefix+h"' \
  "Herdr should focus panes with vim keys"
assert_contains "$herdr_config" 'focus_pane_down = "prefix+j"' \
  "Herdr should focus panes with vim keys"
assert_contains "$herdr_config" 'focus_pane_up = "prefix+k"' \
  "Herdr should focus panes with vim keys"
assert_contains "$herdr_config" 'focus_pane_right = "prefix+l"' \
  "Herdr should focus panes with vim keys"
assert_contains "$herdr_config" 'split_horizontal = "prefix+shift+j"' \
  "Herdr should split downward with prefix+J"
assert_contains "$herdr_config" 'split_vertical = "prefix+shift+l"' \
  "Herdr should split rightward with prefix+L"
assert_contains "$herdr_config" 'resize_mode = "prefix+s"' \
  "Herdr resize mode should match tmux"
assert_contains "$herdr_config" 'reload_config = "prefix+r"' \
  "Herdr reload should match tmux"
assert_contains "$herdr_config" 'detach = "prefix+d"' \
  "Herdr detach should match tmux"
assert_contains "$herdr_config" 'swap_pane_left = ""' \
  "pane swap left should be disabled"
assert_contains "$herdr_config" 'swap_pane_down = ""' \
  "pane swap down should be disabled"
assert_contains "$herdr_config" 'swap_pane_up = ""' \
  "pane swap up should be disabled"
assert_contains "$herdr_config" 'swap_pane_right = ""' \
  "pane swap right should be disabled"
assert_contains "$herdr_config" 'last_pane = "prefix+;"' \
  "Herdr last pane should match tmux"
assert_contains "$herdr_config" 'key = "prefix+shift+h"' \
  "prefix+H should launch Hunk"
assert_contains "$herdr_config" 'command = "hunk diff --watch"' \
  "the Hunk pane should watch the current diff"
assert_contains "$herdr_config" 'close_pane = "prefix+x"' \
  "Herdr pane close should match tmux"
assert_contains "$herdr_config" 'zoom = "prefix+z"' \
  "Herdr pane zoom should match tmux"
assert_contains "$herdr_config" 'toggle_sidebar = "prefix+b"' \
  "Herdr should expose sidebar toggle"
assert_contains "$herdr_config" 'open_notification_target = "prefix+shift+o"' \
  "Herdr should expose notification target focus without conflicting with workspace picker"

assert_contains "$herdr_config" 'sidebar_width = 30' \
  "Herdr should use the balanced sidebar width"
assert_contains "$herdr_config" 'sidebar_collapsed_mode = "compact"' \
  "collapsed sidebar should keep the compact rail"
assert_contains "$herdr_config" 'show_agent_labels_on_pane_borders = true' \
  "pane borders should show agent labels"
assert_contains "$herdr_config" 'hide_tab_bar_when_single_tab = true' \
  "single-tab workspaces should hide the tab bar"
assert_contains "$herdr_config" 'agent_panel_sort = "priority"' \
  "agents should be ordered by attention priority"
assert_contains "$herdr_config" 'delivery = "herdr"' \
  "Herdr should show in-app notifications"
assert_contains "$herdr_config" 'delay_seconds = 1' \
  "Herdr notifications should wait one second"
assert_contains "$herdr_config" 'enabled = true' \
  "Herdr notification sound should be enabled"
assert_contains "$herdr_config" 'pane_history = false' \
  "Herdr should not persist pane screen contents"
```

- [ ] **Step 2: テストを実行してHerdr module未作成で失敗することを確認する**

Run:

```sh
sh tests/herdr_hunk_management_test.sh
```

Expected: `the shared Home Manager tree should import programs/herdr.nix` でFAILする。

- [ ] **Step 3: Herdr config配置moduleを作成してimportする**

`nix/modules/home/programs/herdr.nix` を次の内容で作成する。

```nix
{
  xdg.configFile."herdr/config.toml" = {
    source = ../assets/herdr/config.toml;
    force = true;
  };
}
```

`nix/modules/home/default.nix` のprogram importsへ追加する。

```nix
./programs/herdr.nix
```

配置は `./programs/ghostty.nix` の後、`./programs/hunk.nix` の前とする。

- [ ] **Step 4: 承認済みHerdr configを作成する**

`nix/modules/home/assets/herdr/config.toml` を次の内容で作成する。

```toml
onboarding = false

[theme]
name = "terminal"

[terminal]
new_cwd = "follow"

[keys]
prefix = "ctrl+g"
help = "prefix+?"
settings = "prefix+shift+s"
detach = "prefix+d"
reload_config = "prefix+r"
open_notification_target = "prefix+shift+o"
workspace_picker = "prefix+o"
goto = "prefix+g"
new_workspace = "prefix+shift+n"
new_worktree = "prefix+shift+g"
rename_workspace = "prefix+shift+4"
close_workspace = "prefix+shift+d"
previous_workspace = "prefix+shift+9"
next_workspace = "prefix+shift+0"
new_tab = "prefix+c"
rename_tab = "prefix+comma"
previous_tab = "prefix+p"
next_tab = "prefix+n"
switch_tab = "prefix+1..9"
close_tab = "prefix+ampersand"
copy_mode = "prefix+["
focus_pane_left = "prefix+h"
focus_pane_down = "prefix+j"
focus_pane_up = "prefix+k"
focus_pane_right = "prefix+l"
swap_pane_left = ""
swap_pane_down = ""
swap_pane_up = ""
swap_pane_right = ""
last_pane = "prefix+;"
split_vertical = "prefix+shift+l"
split_horizontal = "prefix+shift+j"
close_pane = "prefix+x"
zoom = "prefix+z"
resize_mode = "prefix+s"
toggle_sidebar = "prefix+b"

[[keys.command]]
key = "prefix+shift+h"
type = "pane"
command = "hunk diff --watch"
description = "review changes with Hunk"

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

[ui.toast]
delivery = "herdr"
delay_seconds = 1

[ui.sound]
enabled = true

[experimental]
pane_history = false
```

- [ ] **Step 5: TOML構文、構造テスト、Nix評価を通す**

Run:

```sh
nix eval --impure --expr 'builtins.fromTOML (builtins.readFile ./nix/modules/home/assets/herdr/config.toml)' >/dev/null
sh tests/herdr_hunk_management_test.sh
nix eval ./nix#darwinConfigurations.KokiAoyagi.system.drvPath
```

Expected: 全commandがexit 0になり、shell testが `Herdr and Hunk management tests passed` を出す。

- [ ] **Step 6: Herdr設定をコミットする**

```sh
git add tests/herdr_hunk_management_test.sh nix/modules/home/default.nix nix/modules/home/programs/herdr.nix nix/modules/home/assets/herdr/config.toml
git commit -m "feat(herdr): add tmux-style Home Manager config"
```

---

### Task 3: リポジトリ内キーバインド資料を追加する

**Files:**
- Modify: `tests/herdr_hunk_management_test.sh`
- Create: `nix/modules/home/assets/herdr/key-bind.md`
- Verify unchanged: `nix/modules/home/programs/herdr.nix`

- [ ] **Step 1: key-bind.mdの内容と非配布を表す失敗テストを追加する**

`tests/herdr_hunk_management_test.sh` の変数へ追加する。

```sh
herdr_key_bind_doc="$repo_root/nix/modules/home/assets/herdr/key-bind.md"
```

成功メッセージの直前へ追加する。

```sh
if [ ! -f "$herdr_key_bind_doc" ]; then
  echo "assets/herdr/key-bind.md should exist"
  exit 1
fi

while IFS= read -r documented_key; do
  [ -n "$documented_key" ] || continue
  assert_contains "$herdr_key_bind_doc" "$documented_key" \
    "key-bind.md should document $documented_key"
done <<'KEYS'
`Ctrl-g`
`prefix+c`
`prefix+p/n`
`prefix+1..9`
`prefix+comma`
`prefix+ampersand`
`prefix+h/j/k/l`
`prefix+Shift+j`
`prefix+Shift+l`
`prefix+[`
`prefix+z`
`prefix+x`
`prefix+s`
`prefix+r`
`prefix+d`
`prefix+;`
`prefix+o`
`prefix+Shift+9/0`
`prefix+Shift+4`
`prefix+Shift+n`
`prefix+Shift+g`
`prefix+Shift+d`
`prefix+g`
`prefix+b`
`prefix+Shift+s`
`prefix+Shift+o`
`prefix+?`
`prefix+Shift+h`
KEYS
assert_contains "$herdr_key_bind_doc" 'session | workspace' \
  "key-bind.md should explain tmux and Herdr concepts"
assert_contains "$herdr_key_bind_doc" 'H/K' \
  "key-bind.md should explain intentionally unassigned splits"

assert_not_contains "$herdr_nix" 'key-bind.md' \
  "Home Manager must not place key-bind.md in the local Herdr config directory"
assert_not_contains "$herdr_nix" 'source = ../assets/herdr;' \
  "Home Manager must source only config.toml, not the whole Herdr asset directory"
```

- [ ] **Step 2: テストを実行してkey-bind.md未作成で失敗することを確認する**

Run:

```sh
sh tests/herdr_hunk_management_test.sh
```

Expected: `assets/herdr/key-bind.md should exist` でFAILする。

- [ ] **Step 3: キーバインド資料を作成する**

`nix/modules/home/assets/herdr/key-bind.md` を次の内容で作成する。

```markdown
# Herdr key bindings

Herdrはtmuxの外側で起動し、prefixにはtmuxと同じ `Ctrl-g` を使う。

## 概念の対応

| tmux | Herdr | 用途 |
|---|---|---|
| session | workspace | repo、task、調査単位の切り替え |
| window | tab | workspace内の画面切り替え |
| pane | pane | 分割ターミナル |
| tmux server/socket | Herdr session | 完全に分離された永続実行環境 |

## tmuxと対応する操作

| キー | Herdr操作 | tmux側の意味 |
|---|---|---|
| `Ctrl-g` | prefix | prefix |
| `prefix+c` | tab作成 | window作成 |
| `prefix+p/n` | 前後のtab | 前後のwindow |
| `prefix+1..9` | 番号でtabへ移動 | 番号でwindowへ移動 |
| `prefix+comma` | tab名変更 | window名変更 |
| `prefix+ampersand` | tabを閉じる | windowを閉じる |
| `prefix+h/j/k/l` | pane focus | pane focus |
| `prefix+Shift+j` | 下にpane分割 | `J` で下に分割 |
| `prefix+Shift+l` | 右にpane分割 | `L` で右に分割 |
| `prefix+[` | copy mode | copy mode |
| `prefix+z` | pane zoom | pane zoom |
| `prefix+x` | paneを閉じる | paneを閉じる |
| `prefix+s` | resize mode | resize mode |
| `prefix+r` | 設定再読み込み | 設定再読み込み |
| `prefix+d` | detach | detach |
| `prefix+;` | 最後のpaneへ戻る | last pane |
| `prefix+o` | workspace picker | tmux-sessionx |
| `prefix+Shift+9/0` | 前後のworkspace | 前後のsession |
| `prefix+Shift+4` | workspace名変更 | session名変更 |

## Herdr固有操作

| キー | 操作 |
|---|---|
| `prefix+Shift+n` | workspace作成 |
| `prefix+Shift+g` | worktree作成 |
| `prefix+Shift+d` | workspaceを閉じる |
| `prefix+g` | Herdr navigator |
| `prefix+b` | sidebar切り替え |
| `prefix+Shift+s` | settings |
| `prefix+Shift+o` | 通知対象へ移動 |
| `prefix+?` | keybinding help |
| `prefix+Shift+h` | focus中paneのcwdで `hunk diff --watch` を開く |

## 意図的に割り当てない操作

- `H/K` のpane分割は使わない。Herdrでは右と下への分割だけを使う。
- tmuxの `<` / `>` に相当するtab並べ替えは、Herdrに対応操作がないため割り当てない。
- `Shift+h/j/k/l` のpane swapは無効にする。`Shift+j/l` は分割、`Shift+h` はHunkに使い、`Shift+k` だけにswapを残さない。
```

- [ ] **Step 4: ドキュメントテストを通し、ローカル配布宣言がないことを確認する**

Run:

```sh
sh tests/herdr_hunk_management_test.sh
rg -n 'key-bind.md|source = ../assets/herdr;' nix/modules/home/programs/herdr.nix
```

Expected: shell testがPASSし、`rg` はexit 1かつ出力なしになる。`herdr.nix` は `config.toml` だけをsourceする。

- [ ] **Step 5: キーバインド資料をコミットする**

```sh
git add tests/herdr_hunk_management_test.sh nix/modules/home/assets/herdr/key-bind.md
git commit -m "docs(herdr): add tmux keybinding reference"
```

---

### Task 4: 全自動テストとNix評価を完了する

**Files:**
- Verify: `tests/herdr_hunk_management_test.sh`
- Verify: `tests/run.sh`
- Verify: `nix/flake.nix`
- Verify: `nix/flake.lock`
- Verify: `nix/modules/home/assets/herdr/config.toml`

- [ ] **Step 1: Herdr TOMLをNix parserで再検証する**

Run:

```sh
nix eval --impure --expr 'builtins.fromTOML (builtins.readFile ./nix/modules/home/assets/herdr/config.toml)' >/dev/null
```

Expected: parse errorなしでexit 0になる。

- [ ] **Step 2: 専用テストを単独実行する**

Run:

```sh
sh tests/herdr_hunk_management_test.sh
```

Expected: `Herdr and Hunk management tests passed`。

- [ ] **Step 3: リポジトリ全テストを実行する**

Run:

```sh
./tests/run.sh
```

Expected: 最後に `all tests passed`。既存の `nix_darwin_reset_test.sh` もHerdrのHomebrew所有を維持したままPASSする。

- [ ] **Step 4: flake全体と両entry pointを評価する**

Run:

```sh
nix flake check ./nix
nix eval ./nix#homeConfigurations.kokiaoyagi.activationPackage.drvPath
nix eval ./nix#darwinConfigurations.KokiAoyagi.system.drvPath
```

Expected: 全commandがexit 0。standalone Linux Home ManagerとmacOS nix-darwinの両方でHunk moduleが評価できる。

- [ ] **Step 5: macOS system derivationをbuildする**

Run:

```sh
nix build ./nix#darwinConfigurations.KokiAoyagi.system --no-link
```

Expected: buildがexit 0。networkまたはsandboxでdependency取得が拒否された場合は、同じcommandを承認付きで再実行する。

- [ ] **Step 6: Taskごとのcommitが揃っていることを確認する**

```sh
git log -n 3 --oneline
```

Expected: `feat(hunk): manage Hunk through Home Manager`、`feat(herdr): add tmux-style Home Manager config`、`docs(herdr): add tmux keybinding reference` の3commitが表示される。検証がFAILした場合は次のTaskへ進まず、失敗原因を特定して該当Taskの実装とテストを修正する。

---

### Task 5: nix-darwinへ適用してHerdrとHunkをスモークテストする

**Files:**
- Apply: `nix#KokiAoyagi`
- Verify runtime: `/Users/KokiAoyagi/.config/herdr/config.toml`
- Verify runtime: `/Users/KokiAoyagi/.config/hunk/config.toml`
- Verify runtime: `/Users/KokiAoyagi/.config/herdr/herdr-server.log`

- [ ] **Step 1: ユーザー承認を得てnix-darwin generationを適用する**

Run:

```sh
sudo darwin-rebuild switch --flake ./nix#KokiAoyagi
```

Expected: activationがexit 0。`/Users/KokiAoyagi/.config/herdr/config.toml` がHome Manager管理へ切り替わり、Hunkがuser profileへ追加される。

- [ ] **Step 2: 配置先とpackage ownershipを確認する**

Run:

```sh
readlink /Users/KokiAoyagi/.config/herdr/config.toml
test ! -e /Users/KokiAoyagi/.config/herdr/key-bind.md
command -v herdr
command -v hunk
herdr --version
hunk --version
brew list --versions herdr
brew list --versions hunk
```

Expected:

- Herdr configはNix store上のassetを指す。
- `/Users/KokiAoyagi/.config/herdr/key-bind.md` は存在しない。
- `herdr` は `/opt/homebrew/bin/herdr`、HunkはNix user profile由来で解決される。
- `brew list --versions herdr` はversionを出す。
- `brew list --versions hunk` は何も出さず、HomebrewがHunkを所有していない。

- [ ] **Step 3: 実行中Herdrへconfig reloadを送り、新規diagnosticを確認する**

Run:

```sh
server_log=/Users/KokiAoyagi/.config/herdr/herdr-server.log
before_lines=$(wc -l < "$server_log")
herdr server reload-config
if tail -n "+$((before_lines + 1))" "$server_log" | \
  rg -i 'config diagnostic|invalid keybinding|disabled binding|reserved keybinding'; then
  echo "Herdr reload produced a new config diagnostic" >&2
  exit 1
fi
```

Expected: reload commandがexit 0。reload後に追加されたlogだけを対象にし、新しいkey conflictやinvalid bindingがない。

- [ ] **Step 4: Herdrのキーバインドを手動確認する**

Herdrをattachし、`Ctrl-g ?` でhelpを開いてから次を確認する。

```text
Ctrl-g c          new tab
Ctrl-g p / n      previous / next tab
Ctrl-g 1..9       switch tab
Ctrl-g o          workspace picker
Ctrl-g ( / )      previous / next workspace
Ctrl-g h/j/k/l    focus pane
Ctrl-g J          split down
Ctrl-g L          split right
Ctrl-g [          copy mode
Ctrl-g s          resize mode
Ctrl-g z          zoom
Ctrl-g r          reload config
Ctrl-g d          detach
```

Expected: 各操作が表どおり動作する。`Ctrl-g K` はpane分割またはpane swapを起こさず、`Ctrl-g H` はHunkだけを起動する。

- [ ] **Step 5: Sidebarと通知を手動確認する**

確認項目:

```text
- sidebar幅が概ね30 columns
- collapse後にcompact status railが残る
- agentがblocked/done/working/idle/unknownのpriority順で表示される
- pane borderにagent labelが表示される
- tabが1つのworkspaceではtab barが隠れる
- background agentのdoneまたはblockedでHerdr内toastが表示され、macOS system notificationは届かない
- 同じ状態変化で通知音が鳴る
```

Expected: 全項目が承認済みBalanced sidebarと通知設計に一致する。

- [ ] **Step 6: Hunk一時paneを手動確認する**

未commit変更があるGit repositoryのpaneをfocusし、`Ctrl-g H` を押す。

Expected:

```text
- focus中paneと同じcwdのdiffがHunkに表示される
- untracked fileを含む
- file変更後にwatch更新される
- terminal背景に合わせたthemeと透明背景になる
- Hunkを終了すると一時paneが閉じる
- 通常のgit diff pagerは変更されていない
```

- [ ] **Step 7: 最終状態を確認する**

Run:

```sh
git status --short
git log -n 5 --oneline
```

Expected: 実装対象ファイルに未commit変更がない。Visual Companionの `.superpowers/` は実装commitに含まれていないことを明示し、必要ならユーザー承認を得て別途削除する。
