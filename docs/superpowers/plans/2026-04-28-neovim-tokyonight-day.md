# Neovim Tokyonight Day Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the active Neovim theme render as a true white `tokyonight-day` theme regardless of WezTerm background opacity.

**Architecture:** Keep the existing `folke/tokyonight.nvim` plugin entry and split its values into a light-oriented preset with explicit non-transparent backgrounds. Keep theme selection in `current-theme.lua`, and verify both config syntax and headless loading after the change.

**Tech Stack:** Neovim Lua config, lazy.nvim, tokyonight.nvim, headless Neovim, `luac`

---

## Chunk 1: Theme preset

### Task 1: Convert the Tokyonight setup to a day preset

**Files:**
- Modify: `.config/nvim/lua/Sethy/plugins/colorscheme.lua`

- [ ] Change the local preset from `style = "night"` to `style = "day"`.
- [ ] Set `transparent = false` for the light preset.
- [ ] Replace `colors.none` background fallbacks with explicit light values for `bg`, `bg_dark`, `bg_float`, `bg_sidebar`, and `bg_statusline`.
- [ ] Keep medium-contrast syntax foreground choices unless a value clearly hurts readability.
- [ ] Run: `luac -p .config/nvim/lua/Sethy/plugins/colorscheme.lua`

## Chunk 2: Active theme selection

### Task 2: Make the day preset the active theme

**Files:**
- Modify: `.config/nvim/lua/current-theme.lua`

- [ ] Confirm `vim.cmd("colorscheme tokyonight-day")` is the active selection.
- [ ] If the file has unrelated user edits, preserve them and only adjust the colorscheme line.
- [ ] Run: `luac -p .config/nvim/lua/current-theme.lua`

## Chunk 3: Regression coverage and verification

### Task 3: Add a small config regression and verify headless load

**Files:**
- Modify: `tests/nvim_web_support_test.lua`

- [ ] Add string assertions that `colorscheme.lua` uses `style = "day"` and `transparent = false`.
- [ ] Add string assertions that the light preset no longer assigns `colors.none` to the main editor background path.
- [ ] Run: `nvim --headless \"+lua dofile('tests/nvim_web_support_test.lua')\" +qa`
- [ ] Run: `nvim --headless \"+lua require('lazy').setup('Sethy.plugins')\" +qa` if the local test environment can load plugins without network access.
- [ ] Commit only the theme-related files after verification.
