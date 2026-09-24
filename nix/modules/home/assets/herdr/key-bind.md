---
created: 2026-07-16
updated: 2026-09-24
author: Koki Aoyagi
type: reference
---

# Herdr key bindings

Herdr runs outside tmux and uses `Ctrl-g` as the same prefix.

## Concepts

| tmux concept | Herdr concept | Meaning |
| --- | --- | --- |
| session | workspace | repo/task/investigation switch |
| window | tab | view inside workspace |
| pane | pane | independently focused terminal region within a tab |
| server/socket | session | fully separate persistent runtime |

## Navigation model

`n/p` は tab、Shift を足すと space (workspace)、`a` は agent。番号で飛ぶのは tab だけ。

| Layer | Previous / next | Jump | New | Close |
| --- | --- | --- | --- | --- |
| tab | `prefix+p` / `prefix+n` | `Ctrl-1..9` (prefix なし) | `prefix+c` | `prefix+Shift+x` |
| space | `prefix+Shift+p` / `prefix+Shift+n` | `prefix+o` (picker) | `prefix+Shift+c` | `prefix+Shift+d` |
| agent | `prefix+Shift+a` / `prefix+a` | — | — | — |

- lowercase が tab、Shift が space という対応を new / close でも揃えている。pane は `prefix+x` で閉じる。
- agent は `agent_panel_sort = "priority"` の順に巡回するので、`prefix+a` で対応が必要な agent から移動できる。

## Other operations

| Key | Operation |
| --- | --- |
| `Ctrl-g` | Prefix |
| `prefix+comma` | Rename tab |
| `prefix+Shift+r` | Rename space |
| `prefix+Shift+g` | New worktree |
| `prefix+w` | Herdr navigator (`g` は lazygit popup に割り当て) |
| `prefix+h/j/k/l` | Focus pane |
| `prefix+Shift+j` | Split down |
| `prefix+Shift+l` | Split right |
| `prefix+;` | Last pane |
| `prefix+[` | Copy mode |
| `prefix+z` | Zoom |
| `prefix+s` | Resize |
| `prefix+b` | Sidebar |
| `prefix+r` | Reload config |
| `prefix+q` | Detach (tmux の `prefix+d` から移動。`d` は lazydocker popup に割り当て) |
| `prefix+Shift+s` | Settings |
| `prefix+Shift+o` | Notification target |
| `prefix+?` | Help |
| `prefix+Shift+h` | Open `hunk diff --watch` in the focused pane's current working directory |

## Popups

All popups are session-modal (80% × 80%) and inherit the focused pane's working directory.

A popup closes only when its command exits; Herdr does not intercept any key (not even Escape) while a popup is open. So `lazygit`/`lazydocker`/`yazi` close on their own `q`, but the scratch terminal is a plain shell — leave it with `exit` or `Ctrl-D`, not `q`.

| Key | Popup |
| --- | --- |
| `prefix+g` | `lazygit` (quit with `q`) |
| `prefix+d` | `lazydocker` (quit with `q`) |
| `prefix+y` | `yazi` (file explorer, quit with `q`) |
| `prefix+t` | Scratch terminal (`$SHELL`, quit with `exit` / `Ctrl-D`) |

## Intentionally unassigned

- Numbered space / agent jumps (`prefix+Shift+1..9`, `prefix+Alt+1..9`) are unassigned: Shift+digit can arrive as a symbol depending on the terminal and keyboard layout, and the picker / priority-ordered agent cycling cover these cases.
- `prefix+1..9` is unassigned because `Ctrl-1..9` already switches tabs directly.
- Direct Ctrl bindings are limited to digits; Ctrl+letter would collide with Neovim and zsh emacs keybindings.
- `rename_pane` is explicitly disabled so its default (`prefix+Shift+p`) cannot collide with previous space.
- `prefix+u` / `prefix+i` / `prefix+e` / `prefix+&` / `prefix+Shift+w` are free.
- H/K pane split bindings are unused because this setup only creates panes to the right or downward.
- Tab reordering and "last tab / last space" toggles are unassigned because Herdr has no corresponding operation.
- All Shift+h/j/k/l pane swaps are disabled: Shift+j/l create splits, Shift+h opens Hunk, and Shift+k is left unassigned to keep the entire pane-swap group consistently disabled.

This reference remains repository-only and is not deployed by the Home Manager module.
