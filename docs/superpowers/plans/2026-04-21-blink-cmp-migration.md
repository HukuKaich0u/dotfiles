# Blink.cmp Migration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move this Neovim config from `nvim-cmp` to `blink.cmp` without breaking snippets or LSP completion.

**Architecture:** Replace the completion frontend first, then update adjacent plugins to remove `cmp`-specific hooks. Keep the LSP server set unchanged in this step so the migration is isolated to completion ownership.

**Tech Stack:** Neovim Lua config, lazy.nvim, blink.cmp, LuaSnip, noice.nvim, nvim-autopairs

---

## Chunk 1: Regression coverage

### Task 1: Update tests for the new completion stack

**Files:**
- Modify: `tests/nvim_web_support_test.lua`

- [ ] Replace `nvim-cmp` assertions with `blink.cmp` assertions.
- [ ] Assert LSP capabilities come from `blink.cmp`.
- [ ] Assert native LSP autotrigger completion is not configured.
- [ ] Run the targeted Lua test and confirm it fails before config changes.

## Chunk 2: Completion migration

### Task 2: Swap the plugin and LSP integration

**Files:**
- Delete: `.config/nvim/lua/Sethy/plugins/nvim-cmp.lua`
- Create: `.config/nvim/lua/Sethy/plugins/blink-cmp.lua`
- Modify: `.config/nvim/lua/Sethy/plugins/lsp/lspconfig.lua`

- [ ] Add a stable `blink.cmp` plugin spec with snippet support and keymaps aligned to current usage.
- [ ] Remove `nvim-cmp`-specific LSP capability wiring.
- [ ] Remove native LSP completion autotrigger setup.

## Chunk 3: Adjacent plugin cleanup

### Task 3: Remove `cmp`-specific glue

**Files:**
- Modify: `.config/nvim/lua/Sethy/plugins/auto-pairs.lua`
- Modify: `.config/nvim/lua/Sethy/plugins/noice.lua`

- [ ] Remove `nvim-cmp` dependency and confirm hook from autopairs.
- [ ] Stop `noice` from requiring the `cmp` popupmenu backend.
- [ ] Keep the rest of the UI behavior unchanged.

## Chunk 4: Verification

### Task 4: Validate the migration

**Files:**
- Modify: `.config/nvim/lazy-lock.json`

- [ ] Run Lua regression tests.
- [ ] Run headless Neovim validation with writable temp XDG dirs.
- [ ] Update the lockfile if plugin resolution changes are recorded.
