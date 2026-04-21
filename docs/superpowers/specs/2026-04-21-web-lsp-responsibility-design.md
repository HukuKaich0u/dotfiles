# Web LSP Responsibility Split Design

**Goal:** Reduce duplicate completions and noisy attach patterns in web buffers by giving each LSP a narrower, explicit filetype responsibility.

## Scope

- Keep the current web stack based on `ts_ls`, `html`, `tailwindcss`, `astro`, `svelte`, and Emmet.
- Reduce overlapping filetypes so the same buffer is not served by multiple general-purpose markup servers.
- Keep framework-specific servers (`astro`, `svelte`) as the source of truth for their own buffers.
- Keep Tailwind support across the current web filetypes.
- Remove the current dual-Emmet setup and keep only one Emmet server.

## Approach

### Responsibility split

- `ts_ls`
  - `javascript`
  - `javascriptreact`
  - `typescript`
  - `typescriptreact`
- `html`
  - `html`
  - `templ`
- `astro`
  - `astro`
- `svelte`
  - `svelte`
- `tailwindcss`
  - `html`
  - `css`
  - `javascript`
  - `typescript`
  - `javascriptreact`
  - `typescriptreact`
  - `astro`
  - `svelte`
- `emmet_language_server`
  - `html`
  - `css`
  - `scss`
  - `sass`
  - `less`
  - `javascriptreact`
  - `typescriptreact`
  - `astro`
  - `svelte`

### Server cleanup

- Remove `emmet_ls` from both `mason` installation and `lspconfig` enablement.
- Keep `emmet_language_server` as the single Emmet provider because it already has the more explicit configuration in the current setup.
- Remove `html` from `javascriptreact`, `typescriptreact`, `astro`, and `svelte` so markup support is not layered on top of framework- or language-specific servers.

### Expected outcome

- `tsx` buffers should attach roughly:
  - `ts_ls`
  - `tailwindcss`
  - `emmet_language_server`
- `html` buffers should attach roughly:
  - `html`
  - `tailwindcss`
  - `emmet_language_server`
- `astro` buffers should attach roughly:
  - `astro`
  - `tailwindcss`
  - `emmet_language_server`
- `svelte` buffers should attach roughly:
  - `svelte`
  - `tailwindcss`
  - `emmet_language_server`

## Error handling

- Do not change formatter behavior or unrelated language servers in this step.
- Do not change `eslint` behavior in this step; that remains a separate decision because it affects diagnostics policy, not just overlap reduction.

## Testing

- Extend the Lua regression test to assert:
  - `emmet_ls` is no longer installed or enabled
  - `html` is no longer assigned to `javascriptreact`, `typescriptreact`, `astro`, or `svelte`
  - `emmet_language_server` remains enabled for the intended markup and component filetypes
- Re-run the existing headless Lua tests.
- Re-run headless Neovim attach sampling in temp buffers to confirm `tsx` no longer pulls in `html` or a second Emmet client.
