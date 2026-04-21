# Neovim C Support Design

**Goal:** Make C development in this Neovim setup feel normal for both single-file programs and Makefile/CMake projects.

## Scope

- Keep `clangd` as the LSP source of truth.
- Add first-class C formatting with `clang-format`.
- Add buffer-local build/run ergonomics for `c`, `cpp`, and related filetypes.
- Prefer existing project build systems when present.
- Document the workflow briefly in the Neovim plugin guide.

## Approach

### LSP and formatting

- Keep the existing `clangd` setup in `lspconfig.lua`.
- Install `clang-format` via `mason-tool-installer`.
- Route `c`, `cpp`, `objc`, and `objcpp` through `conform.nvim` using `clang_format`.
- Continue to use `clangd` for diagnostics, navigation, rename, hover, and `clang-tidy` checks.

### Build and run ergonomics

- Add `after/ftplugin/c.lua` and `after/ftplugin/cpp.lua`.
- For standalone files, set a sensible default compile command using `gcc`/`g++` with warnings enabled and output to the current file stem.
- For project roots containing `Makefile`, `makefile`, or `CMakeLists.txt`, keep `:make` project-oriented instead of forcing a single-file compile.
- Add buffer-local mappings for build and run so C files are usable without extra manual setup.

### Project awareness

- Assume `clangd` works best when `compile_commands.json` exists.
- For CMake projects, document `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`.
- For Makefile projects, document generation via tools such as `bear` when needed, but do not force a repo-global dependency yet.

## Error handling

- If no executable is available after build, run mapping should notify instead of failing silently.
- If a project build system exists, use it rather than guessing a one-file compile.

## Testing

- Validate changed Lua files with headless Neovim startup.
- Check that `conform` resolves `clang_format`.
- Check that the new ftplugin loads without syntax/runtime errors.
