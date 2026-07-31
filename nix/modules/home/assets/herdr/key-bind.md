---
created: 2026-07-16
updated: 2026-07-31
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

## tmux-equivalent operations

| Key | Herdr operation / tmux equivalent |
| --- | --- |
| `Ctrl-g` | Prefix |
| `prefix+c` | New tab / new window |
| `prefix+Shift+p/n` | Previous/next tab/window |
| `prefix+1..9` | Numbered tab/window |
| `prefix+comma` | Rename tab/window |
| `prefix+ampersand` | Close tab/window |
| `prefix+h/j/k/l` | Focus pane |
| `prefix+Shift+j` | Split down (`J`) |
| `prefix+Shift+l` | Split right (`L`) |
| `prefix+[` | Copy mode |
| `prefix+z` | Zoom |
| `prefix+x` | Close pane |
| `prefix+s` | Resize |
| `prefix+r` | Reload |
| `prefix+q` | Detach (tmux の `prefix+d` から移動。`d` は lazydocker popup に割り当て) |
| `prefix+;` | Last pane |
| `prefix+o` | Workspace picker / tmux-sessionx |
| `prefix+p/n` | Previous/next workspace/session |
| `prefix+Shift+r` | Rename workspace/session |

## Herdr-only operations

| Key | Herdr operation |
| --- | --- |
| `prefix+Shift+w` | New workspace |
| `prefix+Shift+g` | New worktree |
| `prefix+Shift+d` | Close workspace |
| `prefix+w` | Herdr navigator (`g` は lazygit popup に割り当て) |
| `prefix+b` | Sidebar |
| `prefix+Shift+s` | Settings |
| `prefix+Shift+o` | Notification target |
| `prefix+?` | Help |
| `prefix+Shift+h` | Open `hunk diff --watch` in the focused pane's current working directory |
| `prefix+a` | Next agent (agent panel order, `a` = agent) |
| `prefix+Shift+a` | Previous agent |
| `prefix+Alt+1..9` | Focus agent by index (tab の `prefix+1..9` に対応) |

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

- `prefix+u` / `prefix+e` are free (previously lazygit / yazi before the mnemonic reshuffle).
- H/K pane split bindings are unused because this setup only creates panes to the right or downward.
- < > tab reordering is unassigned because Herdr has no corresponding tab-reordering operation.
- All Shift+h/j/k/l pane swaps are disabled: Shift+j/l create splits, Shift+h opens Hunk, and Shift+k is left unassigned to keep the entire pane-swap group consistently disabled.

This reference remains repository-only and is not deployed by the Home Manager module.
