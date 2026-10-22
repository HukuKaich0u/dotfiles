---
created: 2026-07-16
updated: 2026-10-22
author: Koki Aoyagi
type: reference
---

# Herdr key bindings

Herdr runs outside tmux and uses `Ctrl-g` as the same prefix.

Validated with Herdr 0.9.5, pinned in `nix/overlays/herdr.nix`.
Home Manager runs `herdr config check` with that package before deploying
`config.toml`. The `popup` commands require a newer schema than Herdr 0.7.1.
After a package update, restart the server once work in its panes is saved;
`reload-config` updates settings within the running version.

## Concepts

| tmux concept | Herdr concept | Meaning |
| --- | --- | --- |
| session | workspace | repo/task/investigation switch |
| window | tab | view inside workspace |
| pane | pane | independently focused terminal region within a tab |
| server/socket | session | fully separate persistent runtime |

## Navigation model

`prefix+w` で Go To を開き、各 workspace の pane に直接移動する。
Workspace picker のショートカットは使わないため解除する。
lazygit は `prefix+g` に割り当てる。

`n/p` は tab、`Shift+n/p` は space (workspace)、`a` は agent。番号で飛ぶのは tab だけ。

| Layer | Previous / next | Jump | New | Close |
| --- | --- | --- | --- | --- |
| tab | `prefix+p` / `prefix+n` | `prefix+1..9` | `prefix+c` | `prefix+Shift+x` |
| space | `prefix+Shift+p` / `prefix+Shift+n` | `prefix+w` (Go To) | `prefix+Shift+c` | `prefix+Shift+d` |
| agent | `prefix+Shift+a` / `prefix+a` | — | — | — |

- lowercase が tab、Shift が space という対応を new / close でも揃えている。pane は `prefix+x` で閉じる。
- agent は `agent_panel_sort = "priority"` の順に巡回するので、`prefix+a` で対応が必要な agent から移動できる。

## Other operations

| Key | Operation |
| --- | --- |
| `Ctrl-g` | Prefix |
| `prefix+Shift+t` | Rename tab |
| `prefix+Shift+w` | Rename space |
| `prefix+Shift+g` | New worktree |
| `prefix+w` | Go To |
| `prefix+h/j/k/l` | Focus pane |
| `prefix+Shift+v` | Vertical split (左右、右に新しい pane) |
| `prefix+Shift+h` | Horizontal split (上下、下に新しい pane) |
| `prefix+;` | Last pane |
| `prefix+[` | Copy mode |
| `prefix+z` | Zoom |
| `prefix+s` | Resize |
| `prefix+b` | Sidebar |
| `prefix+Shift+r` | Reload config |
| `prefix+q` | Detach |
| `prefix+Shift+s` | Settings |
| `prefix+Shift+o` | Notification target |
| `prefix+?` | Help |
| `prefix+Ctrl+h` | Open `hunk diff --watch` in the focused pane's current working directory |

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

- Numbered space / agent jumps (`prefix+Shift+1..9`, `prefix+Alt+1..9`) are unassigned: Shift+digit can arrive as a symbol depending on the terminal and keyboard layout, and Go To / priority-ordered agent cycling cover these cases.
- Tab number jumps use the standard `prefix+1..9`; direct `Ctrl-1..9` bindings are unassigned.
- Custom Ctrl-letter shortcuts require the prefix (`prefix+Ctrl+h` for Hunk) so plain Ctrl-letter input still reaches pane apps.
- Workspace picker is explicitly unassigned; `prefix+w` opens Go To instead.
- Pane rename is explicitly unassigned because it is unused; `prefix+Shift+p` selects the previous workspace.
- `prefix+u` / `prefix+i` / `prefix+&` / `prefix+r` / `prefix+comma` / `prefix+o` are free. `prefix+e` keeps the standard scrollback editor binding.
- Pane splits use `prefix+Shift+v/h`, matching WezTerm, Ghostty, and tmux. New panes open to the right or downward.
- Tab reordering is unassigned, matching the defaults (`move_tab_previous` / `move_tab_next`).
- Shift+h/j/k/l pane swaps are disabled: Shift+h creates a horizontal split; left/right swaps use `prefix+{` / `prefix+}`.

This reference remains repository-only and is not deployed by the Home Manager module.
