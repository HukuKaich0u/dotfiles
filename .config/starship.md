# Starship Notes

This directory contains the prompt config in [`starship.toml`](./starship.toml).

## Current Prompt Structure

The prompt is a two-line layout.

- First line: `hostname` (SSH only), `directory`, `git_branch`, `git_status`, context modules (`docker_context`, `kubernetes`, `terraform`, `direnv`), `cmd_duration`, `time`
- Second line: prompt `character`

## SSH-only Hostname

`hostname` is configured with `ssh_only = true`, so it appears only during SSH sessions.

## Git Modules

### `git_branch`

Shows the current branch name.

Example:

```text
 main
```

### `git_status`

Shows repository state using Starship's default symbols.

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

Example:

```text
✘!?
```

This means:

- `✘`: deleted files exist
- `!`: modified files exist
- `?`: untracked files exist

It does **not** mean merge conflicts unless `=` appears.
