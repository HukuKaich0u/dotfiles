# Blink.cmp Visual Refresh Design

**Goal:** Make insert-mode completion feel visibly more like `blink.cmp` and closer to VS Code without reintroducing noisy cmdline behavior.

## Scope

- Keep `blink.cmp` as the only completion frontend.
- Increase insert completion menu information density.
- Re-enable insert ghost text and auto documentation with a short delay.
- Add explicit borders and highlights so the popup looks intentional.
- Preserve the current cmdline safety settings that prevent `:w` from expanding into `:wall`.

## Approach

### Insert completion UI

- Render completion rows with `kind_icon`, `kind`, `label`, `label_description`, and `source_name`.
- Add custom `source_name` labels so LSP, snippets, paths, and buffer items are easy to distinguish at a glance.
- Use explicit menu and documentation borders plus `BlinkCmp*` highlight groups to make the popup feel more like a dedicated completion surface.

### Completion behavior

- Keep `preselect = false` and `auto_insert = false` so confirm behavior stays conservative.
- Enable insert ghost text only when the menu is visible and an item is selected.
- Auto-show documentation with a short delay so the UI feels richer without becoming immediate noise.

### Cmdline guardrails

- Keep `cmdline.keymap.preset = "cmdline"`.
- Keep `cmdline.completion.menu.auto_show = false`.
- Keep `cmdline.completion.ghost_text.enabled = false`.

## Testing

- Extend the Neovim regression test to assert the richer `blink.cmp` insert UI settings.
- Re-run the headless Lua regression tests and `luac -p` on the edited files.
