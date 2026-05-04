# Neovim LeetCode Integration Design

**Goal:** Add `kawre/leetcode.nvim` to this Neovim setup so LeetCode problems can be opened, run, and submitted inside the existing editor workflow with `Rust` as the default language.

## Scope

- Add `kawre/leetcode.nvim` through the existing `lazy.nvim` plugin layout.
- Keep launch centered on `:Leet` and normal editing sessions rather than `nvim leetcode.nvim`.
- Default LeetCode sessions to `leetcode.com` with `Rust` selected first.
- Support quick switching to `Go` and `C++` through the plugin's built-in language picker.
- Add short local documentation for login and common commands.

## Approach

### Plugin integration

- Create `lua/Sethy/plugins/leetcode.lua` as a dedicated plugin spec following the repo's one-plugin-per-file pattern.
- Load the plugin on `:Leet` and related keymaps so normal startup stays unchanged.
- Declare `plenary.nvim` and `nui.nvim` as local dependencies in that plugin spec.
- Set `picker.provider = "snacks-picker"` so the plugin uses the repo's preferred picker stack explicitly instead of relying on autodetection order.

### Runtime behavior

- Configure `lang = "rust"` and keep `cn.enabled = false` for `leetcode.com`.
- Enable `plugins.non_standalone = true` so LeetCode can open from an existing editing session.
- Keep storage, console sizing, and description layout close to upstream defaults unless this conflicts with the current setup.
- Use the plugin's built-in cookie flow for authentication rather than inventing a separate token or browser automation path.

### Commands over keymaps

- Do not add custom keymaps for LeetCode commands in this repo.
- Rely on the plugin's `:Leet` command family directly to avoid collisions with the existing `<leader>l...` LSP and Rust workflow namespace.
- Document the few commands worth memorizing, such as `:Leet`, `:Leet list`, `:Leet daily`, `:Leet run`, `:Leet submit`, and `:Leet cookie update`.

### Existing language support

- Reuse the current `rustaceanvim`, `gopls`, and `clangd` setup without introducing LeetCode-specific LSP forks.
- Treat LeetCode buffers as regular code buffers first; only add extra filetype or root handling if actual completion/navigation gaps appear after integration.

### Documentation

- Update `docs/plugins-guide.md` with a short LeetCode section.
- Document the login flow, default language choice, and the main `:Leet` commands the user is expected to use.

## Error handling

- If LeetCode API access fails because the cookie expires or the site rate-limits requests, rely on the plugin's existing messaging and document the recovery path.
- Do not hardcode cookies or write login secrets into repo-managed files.

## Testing

- Validate edited Lua files with `luac -p`.
- Run the existing Neovim regression tests that assert config content where appropriate, extending them only if the plugin needs coverage.
- If plugin resolution changes the lockfile, keep that change isolated to the plugin install state.
