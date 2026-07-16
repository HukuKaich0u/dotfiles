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
| `prefix+p/n` | Previous/next tab/window |
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
| `prefix+d` | Detach |
| `prefix+;` | Last pane |
| `prefix+o` | Workspace picker / tmux-sessionx |
| `prefix+Shift+9/0` | Previous/next workspace/session |
| `prefix+Shift+4` | Rename workspace/session |

## Herdr-only operations

| Key | Herdr operation |
| --- | --- |
| `prefix+Shift+n` | New workspace |
| `prefix+Shift+g` | New worktree |
| `prefix+Shift+d` | Close workspace |
| `prefix+g` | Herdr navigator |
| `prefix+b` | Sidebar |
| `prefix+Shift+s` | Settings |
| `prefix+Shift+o` | Notification target |
| `prefix+?` | Help |
| `prefix+Shift+h` | Open `hunk diff --watch` in the focused pane's current working directory |

## Intentionally unassigned

- H/K pane split bindings are unused because this setup only creates panes to the right or downward.
- < > tab reordering is unassigned because Herdr has no corresponding tab-reordering operation.
- All Shift+h/j/k/l pane swaps are disabled because Shift+j/l create splits, Shift+h opens Hunk, and Shift+k is intentionally left without an action.

This reference remains repository-only and is not deployed by the Home Manager module.
