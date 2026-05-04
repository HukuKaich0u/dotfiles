# Neovim LeetCode Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `leetcode.nvim` to this Neovim config for `leetcode.com`, defaulting to `Rust`, usable from `:Leet` inside normal editing sessions.

**Architecture:** Add one dedicated lazy.nvim spec file and keep the rest of the config unchanged. Prefer built-in `:Leet` commands over custom keymaps, document the workflow, and cover the new plugin with lightweight string-based regression checks plus a command-load smoke test.

**Tech Stack:** Neovim Lua config, lazy.nvim, leetcode.nvim, plenary.nvim, nui.nvim, snacks.nvim, Lua regression tests

---

## Chunk 1: Plugin spec

### Task 1: Add leetcode.nvim config

**Files:**
- Create: `.config/nvim/lua/Sethy/plugins/leetcode.lua`

- [ ] Add the `kawre/leetcode.nvim` plugin spec using the repo's single-plugin-file pattern.
- [ ] Load via `cmd = "Leet"` so regular startup stays unchanged.
- [ ] Add local dependencies for `nvim-lua/plenary.nvim` and `MunifTanjim/nui.nvim`.
- [ ] Set `opts.lang = "rust"`, `opts.cn.enabled = false`, `opts.plugins.non_standalone = true`.
- [ ] Set picker behavior per approved spec, without adding custom keymaps.
- [ ] Run: `luac -p .config/nvim/lua/Sethy/plugins/leetcode.lua`

## Chunk 2: Docs and regression coverage

### Task 2: Document the Leet workflow

**Files:**
- Modify: `.config/nvim/docs/plugins-guide.md`

- [ ] Add a short LeetCode section in the plugin guide.
- [ ] Document login via `:Leet cookie update`.
- [ ] Document main commands: `:Leet`, `:Leet list`, `:Leet daily`, `:Leet run`, `:Leet submit`, `:Leet lang`.
- [ ] Note `Rust` default, with manual switching to `Go` or `C++`.

### Task 3: Extend config regression tests

**Files:**
- Modify: `tests/nvim_web_support_test.lua`

- [ ] Assert the repo includes `"kawre/leetcode%.nvim"`.
- [ ] Assert `lang = "rust"`, `cn.enabled = false`, and `non_standalone = true`.
- [ ] Assert no `<leader>l` LeetCode keymaps were introduced in the plugin spec.
- [ ] Run: `nvim --headless "+lua dofile('tests/nvim_web_support_test.lua')" +qa`

## Chunk 3: Load-path verification

### Task 4: Verify command-based lazy loading

**Files:**
- Check: `.config/nvim/lua/Sethy/lazy.lua`
- Check: `.config/nvim/lazy-lock.json`

- [ ] Confirm the new spec is reachable through the existing `import = "Sethy.plugins"` path without touching `lazy.lua`.
- [ ] Run a headless smoke check that loads the config and verifies `:Leet` is defined after lazy resolves the command.
- [ ] Update `lazy-lock.json` only if local plugin resolution records a change.
- [ ] Keep lockfile churn isolated to the LeetCode plugin install state if it changes.
