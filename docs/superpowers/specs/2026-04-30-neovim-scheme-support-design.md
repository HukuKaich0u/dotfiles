# Neovim Scheme Support Design

**Goal:** Make Scheme development comfortable in this Neovim setup by making Racket feel IDE-like while giving other Scheme filetypes solid REPL and editing support.

## Scope

- Make `.rkt` the strongest supported path.
- Improve `.scm` and `.ss` editing without pretending all Scheme dialects have equally strong tooling.
- Add REPL-driven development as a first-class workflow.
- Improve structural editing visibility for parenthesis-heavy code.
- Keep changes aligned with the existing Neovim plugin layout and string-based regression tests.

## Approach

### Racket-first workflow

- Use `racket-langserver` as the LSP source of truth for Racket buffers.
- Use `Conjure` for interactive evaluation so code can be sent to a running REPL from inside Neovim.
- Treat Racket as the default recommendation when the user wants the best editor support for Scheme-family work.

### Cross-dialect baseline

- Enable `Conjure` for `racket`, `scheme`, and related filetypes so `.rkt`, `.scm`, and `.ss` all get an interactive workflow.
- Add Treesitter parsers for `scheme` and `racket` so syntax-aware features work across the supported filetypes.
- Do not add a generic Scheme LSP on day one. Racket gets strong language intelligence first; other dialects keep REPL-centric support.

### Editing UX

- Add rainbow delimiter support so nested forms are easier to read.
- Keep the existing generic editing helpers (`autopairs`, `surround`, `splitjoin`) and layer Lisp-specific tools on top of them instead of replacing them.
- Do not add Parinfer in the first pass. It changes editing behavior materially and is better introduced after the base workflow is stable.

## Components

### Treesitter

- Extend the Treesitter parser install list with `scheme` and `racket`.
- Rely on the existing filetype-wide `vim.treesitter.start()` autocommand so newly installed parsers become active without special-case setup.

### REPL integration

- Add `Olical/conjure` as the primary Scheme interaction plugin.
- Scope its lazy-loading to Lisp/Scheme-related filetypes instead of loading it globally.
- Configure default mappings conservatively so it does not trample existing global LSP or editing keybinds.

### LSP

- Add a local `vim.lsp.config("racket_langserver", ...)` entry.
- Enable it for `racket` buffers and, if the server's defaults allow it cleanly, for `scheme` buffers that are actually Racket-flavored.
- Keep installation explicit rather than assuming Mason can manage it; `racket-langserver` is installed through `raco`, not the current Mason setup.

### Visual structure support

- Add `HiPhish/rainbow-delimiters.nvim`.
- Let it piggyback on Treesitter so delimiter highlighting follows syntax structure instead of regex heuristics.

## External dependencies

- `racket` runtime must be installed locally.
- `racket-langserver` must be installed through `raco pkg install racket-langserver`.
- `Conjure` itself is a plugin dependency only, but useful REPL behavior still depends on an available local Racket runtime.

## Error handling

- If `racket` is unavailable, Neovim should still open Scheme files normally; REPL features simply will not attach.
- If `racket-langserver` is missing, LSP should fail softly without breaking editing, Treesitter, or Conjure startup.
- Avoid eager startup checks that create noise for users who are editing dotfiles rather than Scheme code.

## Testing

- Extend the existing Neovim config regression tests with assertions that:
  - Treesitter installs `scheme` and `racket`.
  - `Conjure` is installed and scoped to Scheme/Racket filetypes.
  - `racket_langserver` is configured and enabled.
  - rainbow delimiter support is present.
- Validate changed Lua files with `luac -p`.
- If practical, run a headless Neovim load to catch plugin spec or syntax errors.

## Non-goals

- Full parity across every Scheme implementation.
- Formatter integration in the first pass.
- Parinfer or Paredit-style structural editing beyond what existing tools and Conjure already provide.
