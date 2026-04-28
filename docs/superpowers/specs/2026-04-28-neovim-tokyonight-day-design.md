# Neovim Tokyonight Day Design

**Goal:** Make the Neovim light theme use a true white background by basing it on `tokyonight-day` and removing dependence on WezTerm transparency.

## Scope

- Keep `folke/tokyonight.nvim` as the theme plugin.
- Add a dedicated `tokyonight-day` preset for readable light-mode editing.
- Disable Neovim background transparency for the light preset.
- Preserve a small amount of UI separation in floats, sidebars, and status surfaces.
- Do not change WezTerm colors or opacity as part of this work.

## Approach

### Theme baseline

- Switch the light preset to `style = "day"`.
- Set `transparent = false` for the light preset so editor backgrounds are painted by Neovim instead of inherited from WezTerm.
- Keep the existing `tokyonight` plugin entry and implement the light configuration inside that setup path rather than introducing a second theme plugin.

### Color treatment

- Use a white editor background for the main editing surface.
- Give `bg_float`, `bg_sidebar`, and `bg_statusline` slightly off-white values so overlays remain visually separated without becoming heavy panels.
- Keep syntax contrast at a medium level that still feels like `tokyonight`, prioritizing code readability over decorative saturation.

### Integration

- Update the active theme selection so the day preset can be used as the normal theme.
- Avoid changes to WezTerm because the problem is caused by Neovim transparency, not terminal palette correctness.
- Keep the existing night-oriented overrides available unless they directly block the day preset structure.

## Testing

- Run `luac -p` against the edited Neovim Lua files.
- Inspect the resulting highlight settings in the theme config to confirm backgrounds are no longer set to `colors.none` for the day preset.
- If there is an existing Neovim regression test that covers theme config, extend it; otherwise rely on syntax validation for this config-only change.
