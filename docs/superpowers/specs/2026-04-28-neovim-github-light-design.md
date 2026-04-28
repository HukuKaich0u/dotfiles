# Neovim Github Light Design

**Goal:** Add `github-nvim-theme` as a readable light-theme option, make `github_light` the active theme, keep `tokyonight-day` available for comparison, and stop local `.tmp` test artifacts from appearing as untracked files.

## Scope

- Add `projekt0n/github-nvim-theme` to the Neovim theme plugin list.
- Configure a `github_light` preset with non-transparent light backgrounds.
- Switch the active theme selection to `github_light`.
- Keep the existing `tokyonight-day` setup in place so the user can switch back easily.
- Ignore `.tmp/` in git so local Neovim test state stays out of the worktree.

## Approach

### Theme integration

- Add the theme through the existing `colorscheme.lua` plugin registry.
- Configure `require("github-theme").setup` with `transparent = false` and light-friendly defaults.
- Prefer the built-in `github_light` palette first, adding only small overrides if the default background separation is insufficient.

### Theme selection

- Update `current-theme.lua` so the active colorscheme is `github_light`.
- Keep the `tokyonight-day` plugin block intact rather than replacing it, so the user can compare themes without re-adding configuration.

### Worktree hygiene

- Add `.tmp/` to the repo-root `.gitignore`.
- Do not remove or modify unrelated untracked files outside this request.

## Testing

- Extend the Neovim config regression test to assert the presence of `github-nvim-theme` and `colorscheme github_light`.
- Run `luac -p` against edited Lua files.
- Run the existing headless Lua regression test for Neovim config string assertions.
- If `github-nvim-theme` requires recompilation for visual changes, note the `:GithubThemeCompile` step in the final report.
