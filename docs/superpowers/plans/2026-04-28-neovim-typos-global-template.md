# Neovim Typos Global Template Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Improve the global Neovim `typos.toml` template so it supports both reusable allowed words and case-sensitive identifiers.

**Architecture:** Keep the existing global `typos_lsp` integration untouched and only refine the contents of `.config/nvim/typos.toml`. If needed, extend the existing regression test to assert the new identifier section so the template shape stays stable.

**Tech Stack:** TOML config, Neovim Lua regression tests, typos-lsp

---

## Chunk 1: Global typos template

### Task 1: Expand the global typos.toml template

**Files:**
- Modify: `.config/nvim/typos.toml`

- [ ] Keep the existing `extend-words` entries.
- [ ] Improve comments so the file explains when to use `extend-words`.
- [ ] Add a new `extend-identifiers` section with practical examples or commented examples.
- [ ] Preserve the existing `[files]` exclusions.

## Chunk 2: Regression coverage

### Task 2: Extend typos-lsp regression coverage

**Files:**
- Modify: `tests/nvim_typos_lsp_test.lua`

- [ ] Add an assertion that the global config defines `[default.extend-identifiers]`.
- [ ] Keep the current assertions for the global config path and `extend-words`.
- [ ] Run: `nvim --headless \"+lua dofile('tests/nvim_typos_lsp_test.lua')\" +qa`
- [ ] Commit only the typos template and test updates after verification.
