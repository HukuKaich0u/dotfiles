# Web LSP Responsibility Split Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce duplicate web completions by narrowing `html` and Emmet ownership in this Neovim config.

**Architecture:** Keep framework servers (`astro`, `svelte`) and `ts_ls` as primary owners of their buffers. Remove the second Emmet server, shrink `html` to real HTML-like files, and lock the result with static + attach-sampling tests.

**Tech Stack:** Neovim Lua config, lspconfig, mason.nvim, headless Neovim Lua tests

---

## Chunk 1: Regression tests

### Task 1: Add failing overlap tests

**Files:**
- Modify: `tests/nvim_web_support_test.lua`

- [ ] Add assertions: `mason.lua` no longer installs `emmet_ls`.
- [ ] Add assertions: `lspconfig.lua` no longer enables `emmet_ls`.
- [ ] Add assertions: `html` filetypes only include `html` and `templ`.
- [ ] Add assertions: `emmet_language_server` keeps `jsx/tsx/astro/svelte`.
- [ ] Run: `XDG_STATE_HOME=/tmp/codex-state XDG_CACHE_HOME=/tmp/codex-cache nvim --headless -u NONE -c 'luafile tests/nvim_web_support_test.lua' -c 'qa'`
- [ ] Expect: FAIL on missing patterns before config edits.

## Chunk 2: LSP responsibility split

### Task 2: Remove duplicate web servers

**Files:**
- Modify: `.config/nvim/lua/Sethy/plugins/lsp/lspconfig.lua`
- Modify: `.config/nvim/lua/Sethy/plugins/lsp/mason.lua`

- [ ] Remove `emmet_ls` config block.
- [ ] Remove `vim.lsp.enable("emmet_ls")`.
- [ ] Remove `emmet_ls` from Mason `ensure_installed`.
- [ ] Shrink `html.filetypes` to `html`, `templ`.
- [ ] Keep `ts_ls`, `astro`, `svelte`, `tailwindcss`, `emmet_language_server` filetypes aligned with spec.

## Chunk 3: Runtime proof

### Task 3: Prove attach counts dropped

**Files:**
- Modify: `tests/nvim_web_support_test.lua`

- [ ] Run temp-buffer sampling for `test.tsx`.
- [ ] Command: `mkdir -p /tmp/codex-nvim-test /tmp/codex-state /tmp/codex-cache && printf 'const App = () => <div className=\"text-red-500\"></div>\\n' > /tmp/codex-nvim-test/test.tsx && XDG_STATE_HOME=/tmp/codex-state XDG_CACHE_HOME=/tmp/codex-cache nvim --headless /tmp/codex-nvim-test/test.tsx '+lua vim.defer_fn(function() for _,c in ipairs(vim.lsp.get_clients({buf=0})) do print(c.name) end; vim.cmd(\"qa\") end, 5000)'`
- [ ] Expect: `ts_ls`, `tailwindcss` if project context available, `emmet_language_server`; not `html`, not `emmet_ls`.

## Chunk 4: Verification

### Task 4: Re-run checks

**Files:**
- Modify: `.config/nvim/lazy-lock.json` only if plugin state changes unexpectedly

- [ ] Run: `XDG_STATE_HOME=/tmp/codex-state XDG_CACHE_HOME=/tmp/codex-cache nvim --headless -u NONE -c 'luafile tests/nvim_web_support_test.lua' -c 'qa'`
- [ ] Expect: PASS.
- [ ] Run: `XDG_STATE_HOME=/tmp/codex-state XDG_CACHE_HOME=/tmp/codex-cache nvim --headless -u NONE -c 'luafile tests/nvim_env_test.lua' -c 'qa'`
- [ ] Expect: PASS.
- [ ] Run: `luac -p .config/nvim/lua/Sethy/plugins/lsp/lspconfig.lua .config/nvim/lua/Sethy/plugins/lsp/mason.lua tests/nvim_web_support_test.lua`
- [ ] Expect: no output.

## Unresolved Questions

- Current worktree is `main` and dirty. Need explicit approval to keep implementing here, or switch to a new worktree/branch first.
