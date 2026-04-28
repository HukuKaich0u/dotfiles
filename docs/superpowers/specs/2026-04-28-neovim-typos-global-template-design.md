# Neovim Typos Global Template Design

**Goal:** Improve the global Neovim `typos.toml` so it serves as a practical template for both allowed words and case-sensitive identifiers while preserving the existing global `typos_lsp` workflow.

## Scope

- Update `.config/nvim/typos.toml`.
- Keep the existing global-file approach used by `typos_lsp`.
- Preserve current allowlist entries unless they are clearly redundant.
- Add template guidance for both `extend-words` and `extend-identifiers`.
- Optionally extend the regression test to assert the presence of the new identifier section.

## Approach

### Template structure

- Keep `[default.extend-words]` as the main area for lowercased dictionary exceptions.
- Add `[default.extend-identifiers]` for case-sensitive symbol names and branded identifiers.
- Use short comments that explain when each section should be used, without turning the file into documentation noise.

### Existing entries

- Preserve existing entries like `teh`, `koki`, and `hukukaich0u`.
- Add small example entries or commented examples only where they clarify intended usage.

### Validation

- If test coverage is updated, assert that the global config now defines both `extend-words` and `extend-identifiers`.
- Do not change the current `typos_lsp` integration path in Neovim as part of this task.

## Testing

- Run `luac -p` only if any Lua files change.
- Run the existing `tests/nvim_typos_lsp_test.lua` regression, extending it if needed.
