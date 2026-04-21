# C Neovim Support Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add practical C development support to this Neovim config for single-file and Make/CMake workflows.

**Architecture:** Extend the existing `mason`, `lspconfig`, and `conform` setup instead of adding a parallel C stack. Put build/run behavior in ftplugin files so it only applies to C-family buffers and can stay project-aware.

**Tech Stack:** Neovim Lua config, lazy.nvim, mason.nvim, conform.nvim, clangd, clang-format

---

## Chunk 1: Tooling integration

### Task 1: Install and wire C formatting

**Files:**
- Modify: `.config/nvim/lua/Sethy/plugins/lsp/mason.lua`
- Modify: `.config/nvim/lua/Sethy/plugins/conform.lua`

- [ ] Add `clang-format` to Mason-managed tools.
- [ ] Route `c`, `cpp`, `objc`, and `objcpp` to `clang_format` in Conform.
- [ ] Validate Lua syntax with headless Neovim.

## Chunk 2: Buffer-local C workflow

### Task 2: Add C/C++ ftplugin behavior

**Files:**
- Create: `.config/nvim/after/ftplugin/c.lua`
- Create: `.config/nvim/after/ftplugin/cpp.lua`

- [ ] Detect whether the current buffer is in a Make/CMake project.
- [ ] For standalone files, set default compile command and executable path.
- [ ] Add buffer-local build/run mappings.
- [ ] Validate ftplugin load in headless Neovim.

## Chunk 3: Docs

### Task 3: Document the workflow

**Files:**
- Modify: `.config/nvim/docs/plugins-guide.md`

- [ ] Update formatter table for C/C++.
- [ ] Add short C workflow notes for standalone and project-based development.
- [ ] Re-run headless Neovim validation after doc-adjacent config changes.
