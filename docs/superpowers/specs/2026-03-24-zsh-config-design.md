# Zsh Config Migration Design

## Goal

Move shell configuration management into the repository-managed `.config` tree while keeping `~/.zshrc` and `~/.zprofile` as thin entrypoints. Manage interactive `zsh`, `starship`, and Homebrew-installed `zsh` plugins from this repository with minimal duplication and predictable load order.

## Current State

- The repository currently tracks [`/.zshrc`] as a home-directory dotfile and links it to `~/.zshrc` from [`/Users/KokiAoyagi/Documents/repos/dotfiles/install.sh`].
- `.config/` is already used for other tools such as `nvim`, `tmux`, and `wezterm`.
- `~/.zprofile` is currently unused.
- `zsh-autosuggestions` and `zsh-syntax-highlighting` are already installed via Homebrew.

## Design Summary

Keep home-directory `zsh` files minimal and move the actual configuration into `.config/zsh`. The repo will own all configuration logic. Homebrew will continue to own plugin binaries and scripts.

The migration will introduce a small `zsh` config tree:

- `.config/zsh/.zshrc`
- `.config/zsh/.zprofile`
- `.config/zsh/env.zsh`
- `.config/zsh/aliases.zsh`
- `.config/zsh/completion.zsh`
- `.config/zsh/plugins.zsh`
- `.config/starship.toml`

The repository root `.zshrc` and a new repository root `.zprofile` will become thin wrappers that `source` the corresponding files under `.config/zsh`. This preserves the installer's current "link selected home dotfiles from the repo root" model without requiring `ZDOTDIR`.

## File Responsibilities

### `.config/zsh/.zprofile`

Purpose:
- Login-shell-only setup
- Minimal initialization that should not rerun for every interactive subshell

Initial scope:
- Keep this file empty or near-empty until a real login-only requirement exists
- Allow future PATH or environment initialization that specifically belongs in login shells

### `.config/zsh/.zshrc`

Purpose:
- Interactive shell entrypoint for the real configuration
- Define deterministic load order by sourcing focused config files

Load order:
1. `env.zsh`
2. `aliases.zsh`
3. `completion.zsh`
4. `plugins.zsh`

This file should stay short and contain only path discovery plus `source` calls.

### `.config/zsh/env.zsh`

Purpose:
- Centralize exported environment variables and PATH management

Initial content migrated from the existing `.zshrc`:
- existing PATH additions
- `PNPM_HOME`
- `CPLUS_INCLUDE_PATH`
- `conda` initialization block
- `gcloud` path/completion init if it is treated as environment bootstrapping
- any other `export` statements from the current file

Constraints:
- Remove accidental duplication during migration, especially the repeated `PNPM_HOME` block
- Preserve current behavior unless a duplication is clearly redundant

### `.config/zsh/aliases.zsh`

Purpose:
- Centralize interactive shell aliases

Initial content:
- competitive programming aliases
- editor/tmux/Codex aliases

### `.config/zsh/completion.zsh`

Purpose:
- Own completion system initialization and related interactive completion settings

Initial content:
- `autoload -Uz compinit`
- `compinit`
- any completion-specific settings added during cleanup

### `.config/zsh/plugins.zsh`

Purpose:
- Load third-party interactive enhancements in safe order

Initial content:
- `starship` initialization
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- existing `bindkey` setting for multiline editing if it remains an interactive concern

Load-order constraints:
- completion setup must happen before plugin sourcing
- `zsh-syntax-highlighting` must be sourced last among interactive plugins

Plugin discovery:
- Resolve Homebrew-managed plugin paths from standard Homebrew prefixes instead of hardcoding only one location
- Prefer checking `brew --prefix <formula>` when available
- If `brew` is not available in the current shell, fall back to known common prefixes such as `/opt/homebrew` and `/usr/local`
- Missing plugins should fail softly: do not abort shell startup

## Wrapper Files In The Home Directory

The repository root files will be the source of truth for the linked home-directory entrypoints.

### Root `.zshrc`

Behavior:
- Only `source "$HOME/Documents/repos/dotfiles/.config/zsh/.zshrc"` or an equivalent path based on the file's own directory

### Root `.zprofile`

Behavior:
- Only `source "$HOME/Documents/repos/dotfiles/.config/zsh/.zprofile"` or an equivalent path based on the file's own directory

Rationale:
- Home-directory files remain tiny and disposable
- Real configuration lives in `.config`
- Installer can keep linking root dotfiles without introducing `ZDOTDIR`

## Installer Changes

[`/Users/KokiAoyagi/Documents/repos/dotfiles/install.sh`] will be updated so that:

- both `.zshrc` and `.zprofile` are linked into the home directory
- `.config/zsh` and `.config/starship.toml` are installed via the existing `.config` symlink strategy

No plugin installation will be added to the installer because Homebrew remains the source of those dependencies.

## Error Handling

- Missing Homebrew plugin files must not break shell startup
- Missing `starship` binary must not break shell startup
- Wrapper files should no-op only if the target file is missing, ideally with a simple existence guard

## Non-Goals

- Switching to `ZDOTDIR`
- Introducing a `zsh` plugin manager
- Rewriting the current shell behavior beyond cleanup and organization
- Auto-installing Homebrew formulas from the dotfiles installer

## Testing Strategy

Validate the migration with lightweight shell-level checks:

- `zsh -n` on the wrapper files and the new sourced files
- an interactive login shell smoke test such as `zsh -lic exit`
- installer smoke test to confirm `.zprofile` is linked alongside `.zshrc`
- manual verification that prompt, autosuggestions, and syntax highlighting still load

## Open Decisions Resolved

- Use `source`-based thin wrappers instead of `ZDOTDIR`
- Keep `~/.zprofile` available but minimal
- Load `zsh-autosuggestions` and `zsh-syntax-highlighting` from Homebrew-managed install locations
- Migrate incrementally: create repo-side structure first, then switch home entrypoints
