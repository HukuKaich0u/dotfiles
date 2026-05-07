# Starship Notes

このディレクトリには、[`starship.toml`](./starship.toml) の prompt 設定が入っています。

## Current Prompt Structure

prompt は 2 行構成です。

- 1 行目: `hostname` (SSH のときだけ), `directory`, `git_branch`, `git_status`, context modules (`docker_context`, `kubernetes`, `terraform`, `direnv`), `cmd_duration`, `time`
- 2 行目: prompt `character`

## SSH-only Hostname

`hostname` には `ssh_only = true` を設定しているので、SSH session のときだけ表示されます。

## Git Modules

### `git_branch`

現在の branch 名を表示します。

例:

```text
 main
```

### `git_status`

Starship のデフォルト記号で repository の状態を表示します。

- `=`: conflicted
- `⇡`: ahead
- `⇣`: behind
- `⇕`: diverged
- `?`: untracked
- `$`: stashed
- `!`: modified
- `+`: staged
- `»`: renamed
- `✘`: deleted

例:

```text
✘!?
```

これは次の意味です。

- `✘`: deleted files がある
- `!`: modified files がある
- `?`: untracked files がある

`=` が出ていない限り、merge conflict を意味しているわけではありません。
