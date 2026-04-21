# Blink.cmp Migration Design

**Goal:** Replace `nvim-cmp` with `blink.cmp` so Neovim completion uses one frontend with simpler defaults and less configuration drift.

## Scope

- Remove `nvim-cmp` and its companion source plugins from the local config.
- Add `blink.cmp` pinned to the stable v1 line.
- Keep `LuaSnip` and `friendly-snippets` so snippet behavior survives the migration.
- Rewire LSP capabilities and disable native LSP completion autotrigger so completion ownership is unambiguous.
- Remove `cmp`-specific integrations from adjacent plugins.

## Approach

### Completion frontend

- Replace `.config/nvim/lua/Sethy/plugins/nvim-cmp.lua` with a `blink.cmp` plugin spec.
- Preserve the current interaction style where possible:
  - `Ctrl-n` / `Ctrl-p` to move through items
  - `Ctrl-b` / `Ctrl-f` to scroll docs
  - `Ctrl-Space` to trigger completion
  - `Tab` / `Shift-Tab` to move snippets and completion selection
- Prefer a safer confirm path by avoiding the current `select = true` behavior from `nvim-cmp`.

### LSP integration

- Replace `cmp_nvim_lsp.default_capabilities()` with `blink.cmp.get_lsp_capabilities()`.
- Remove `vim.lsp.completion.enable(..., { autotrigger = true })` so built-in LSP completion does not compete with `blink.cmp`.

### Adjacent plugin cleanup

- Remove the `nvim-cmp` dependency and `confirm_done` hook from `nvim-autopairs`.
- Disable or simplify `noice` popupmenu integration so it no longer expects the `cmp` backend.
- Keep Tailwind colorizer support unchanged because it is independent from completion ownership.

## Error handling

- Pin `blink.cmp` to the stable major version to avoid an accidental jump to v2 development.
- Keep snippet support optional at runtime through `LuaSnip`, rather than adding a second migration at the same time.

## Testing

- Update the Neovim config regression test to assert `blink.cmp` usage instead of `nvim-cmp`.
- Run the Lua-based tests already in `tests/`.
- Run headless Neovim validation where possible without requiring unrelated user-state paths.
