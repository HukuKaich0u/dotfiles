# Neovim Github Light Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `github-nvim-theme`, make `github_light` the active theme, keep `tokyonight-day` available, and ignore local `.tmp` artifacts.

**Architecture:** Extend the existing theme registry in `colorscheme.lua` with a dedicated `github-nvim-theme` block, switch active selection in `current-theme.lua`, and cover the new selection with string-based Neovim config regression tests. Keep the cleanup of `.tmp/` isolated to `.gitignore`.

**Tech Stack:** Neovim Lua config, lazy.nvim, github-nvim-theme, Lua regression tests, git ignore rules

---

## Chunk 1: Theme plugin integration

### Task 1: Add github-nvim-theme to the colorscheme registry

**Files:**
- Modify: `.config/nvim/lua/Sethy/plugins/colorscheme.lua`

- [ ] Add the `projekt0n/github-nvim-theme` plugin entry using the repo's existing lazy.nvim pattern.
- [ ] Configure `require("github-theme").setup` with `transparent = false` and light-oriented defaults.
- [ ] Keep the existing `tokyonight-day` block intact for comparison.
- [ ] Run: `luac -p .config/nvim/lua/Sethy/plugins/colorscheme.lua`

## Chunk 2: Active theme selection

### Task 2: Point the active colorscheme at github_light

**Files:**
- Modify: `.config/nvim/lua/current-theme.lua`

- [ ] Change the active colorscheme line to `vim.cmd("colorscheme github_light")`.
- [ ] Preserve the file as a single-purpose selector without adding extra logic.
- [ ] Run: `luac -p .config/nvim/lua/current-theme.lua`

## Chunk 3: Ignore local temp artifacts

### Task 3: Ignore `.tmp/`

**Files:**
- Modify: `.gitignore`

- [ ] Add `.tmp/` near the existing local state and log ignores.
- [ ] Do not alter unrelated ignore rules.

## Chunk 4: Regression coverage and verification

### Task 4: Extend tests for github_light

**Files:**
- Modify: `tests/nvim_web_support_test.lua`

- [ ] Assert that `colorscheme.lua` includes `projekt0n/github%-nvim%-theme`.
- [ ] Assert that `current-theme.lua` selects `github_light`.
- [ ] Keep the existing `tokyonight-day` light-theme assertions unless the new setup makes them incorrect.
- [ ] Run: `nvim --headless \"+lua dofile('tests/nvim_web_support_test.lua')\" +qa`
- [ ] Commit only the theme and ignore-rule changes after verification.
