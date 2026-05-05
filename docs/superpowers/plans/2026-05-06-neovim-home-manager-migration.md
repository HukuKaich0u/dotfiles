# Neovim Home Manager Migration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `nvim` into Home Manager without redesigning the Lua config, while keeping `mason` as the owner of LSP/formatter distribution and moving only `mason`-external dependencies into Nix.

**Architecture:** Add `nix/home-manager/nvim.nix` as the Home Manager entry point for `programs.neovim`, `home.packages`, and `xdg.configFile."nvim"`. Move the existing config tree from `.config/nvim` to `nix/home-manager/nvim`, update installer/tests to follow the new source-of-truth path, and explicitly disable `rustowl` and `image.nvim` for Phase 1.

**Tech Stack:** Nix, Home Manager, nix-darwin flake, Neovim Lua config, shell regression tests, Lua regression tests, `install.sh`

---

## Chunk 1: migration shape and test harness

### Task 1: Lock the Home Manager wiring with a failing shell test

**Files:**
- Create: `tests/nvim_home_manager_migration_test.sh`
- Check: `nix/home-manager/home.nix`
- Check: `nix/home-manager/nvim.nix`
- Check: `install.sh`

- [ ] Write a failing shell test that asserts:
- [ ] `home.nix` imports `./nvim.nix`
- [ ] `nvim.nix` exists
- [ ] `programs.neovim = {` and `enable = true;` exist
- [ ] `xdg.configFile."nvim"` points at `./nvim`
- [ ] `home.packages` contains the agreed Phase 1 dependencies
- [ ] `install.sh` skip list contains `nvim`
- [ ] legacy repo source `.config/nvim` no longer exists
- [ ] Run: `bash tests/nvim_home_manager_migration_test.sh`
- [ ] Expected: FAIL because `nvim.nix`, skip wiring, and source relocation do not exist yet

### Task 2: Point Neovim regression tests at the new source tree

**Files:**
- Modify: `tests/nvim_env_test.lua`
- Modify: `tests/nvim_nix_shell_support_test.lua`
- Modify: `tests/nvim_typos_lsp_test.lua`
- Modify: `tests/nvim_web_support_test.lua`
- Modify: `tests/nvim_leetcode_test.lua`

- [ ] Change hardcoded reads from `.config/nvim/...` to `nix/home-manager/nvim/...`
- [ ] Keep assertions identical; only move the source path
- [ ] Run each test once before implementation:
- [ ] `lua tests/nvim_env_test.lua`
- [ ] `lua tests/nvim_nix_shell_support_test.lua`
- [ ] `lua tests/nvim_typos_lsp_test.lua`
- [ ] `lua tests/nvim_web_support_test.lua`
- [ ] `lua tests/nvim_leetcode_test.lua`
- [ ] Expected: at least path-related failures until config is moved

## Chunk 2: Home Manager module and config relocation

### Task 3: Create `nix/home-manager/nvim.nix`

**Files:**
- Create: `nix/home-manager/nvim.nix`
- Modify: `nix/home-manager/home.nix`

- [ ] Add a new Home Manager module with `programs.neovim.enable = true;`
- [ ] Decide and encode any simple editor flags kept with program ownership:
- [ ] `defaultEditor = true;` if consistent with current repo usage
- [ ] `viAlias` / `vimAlias` only if they match current behavior and do not widen scope
- [ ] Import `./nvim.nix` from `nix/home-manager/home.nix`
- [ ] Run: `bash tests/nvim_home_manager_migration_test.sh`
- [ ] Expected: still FAIL because config tree, dependencies, and installer updates are not done yet

### Task 4: Move the config tree under Home Manager ownership

**Files:**
- Create: `nix/home-manager/nvim/` (mirror full existing tree)
- Remove: `.config/nvim/**`
- Modify: `nix/home-manager/nvim.nix`

- [ ] Copy the full existing Neovim tree from `.config/nvim/` to `nix/home-manager/nvim/`
- [ ] Preserve file layout exactly:
- [ ] `init.lua`
- [ ] `lazy-lock.json`
- [ ] `lua/**`
- [ ] `after/**`
- [ ] `docs/**`
- [ ] `typos.toml`
- [ ] Wire `xdg.configFile."nvim".source = ./nvim;`
- [ ] Delete the legacy `.config/nvim` tree after the new copy is in place
- [ ] Run: `bash tests/nvim_home_manager_migration_test.sh`
- [ ] Expected: may still FAIL until dependencies and plugin exclusions are handled

### Task 5: Encode Phase 1 package ownership in `nvim.nix`

**Files:**
- Modify: `nix/home-manager/nvim.nix`
- Check: `docs/superpowers/specs/2026-05-06-neovim-home-manager-migration-design.md`

- [ ] Add `home.packages` entries for the agreed `mason`-external dependencies
- [ ] Include:
- [ ] `git`
- [ ] `ripgrep`
- [ ] `fd`
- [ ] `make`
- [ ] `tmux`
- [ ] `lazygit`
- [ ] `imagemagick`
- [ ] `pngpaste`
- [ ] `ascii-image-converter`
- [ ] Do not add Mason-owned LSP/formatter packages in this phase
- [ ] Run: `bash tests/nvim_home_manager_migration_test.sh`
- [ ] Expected: PASS

## Chunk 3: explicit Phase 1 exclusions

### Task 6: Disable `rustowl` for Phase 1

**Files:**
- Modify: `nix/home-manager/nvim/lua/Sethy/plugins/lsp/rustowl.lua`
- Test: `tests/nvim_nix_shell_support_test.lua`

- [ ] Replace the unconditional plugin spec with a clearly disabled Phase 1 form
- [ ] Keep a short comment that `rustowl` is deferred because it currently depends on `cargo binstall`
- [ ] Avoid changing unrelated Rust plugin behavior
- [ ] Run: `lua tests/nvim_nix_shell_support_test.lua`
- [ ] Expected: PASS

### Task 7: Disable `image.nvim` and image clipboard integrations for Phase 1

**Files:**
- Modify: `nix/home-manager/nvim/lua/Sethy/plugins/image-support.lua`
- Modify: `nix/home-manager/nvim/lua/Sethy/plugins/snacks.lua`
- Modify: `nix/home-manager/nvim/lua/Sethy/core/env.lua`
- Test: `tests/nvim_env_test.lua`

- [ ] Disable `3rd/image.nvim` for this phase without deleting the file
- [ ] Disable or gate `img-clip.nvim` if it relies on the same deferred image workflow
- [ ] Ensure `snacks` image settings do not assume `image.nvim` or luarocks-based magick support
- [ ] Keep dashboard image support only if it works with Phase 1 dependencies alone; otherwise disable that section too
- [ ] Add short comments marking the feature as deferred
- [ ] Run: `lua tests/nvim_env_test.lua`
- [ ] Expected: PASS

## Chunk 4: installer, validation, and build checks

### Task 8: Stop `install.sh` from relinking Neovim

**Files:**
- Modify: `install.sh`
- Test: `tests/nvim_home_manager_migration_test.sh`
- Regression checks: `tests/bacon_home_manager_migration_test.sh`, `tests/wezterm_home_manager_migration_test.sh`, `tests/yazi_home_manager_migration_test.sh`, `tests/zsh_nix_migration_test.sh`

- [ ] Add `nvim` to `SKIP_CONFIG_DIRS`
- [ ] Run:
- [ ] `bash tests/nvim_home_manager_migration_test.sh`
- [ ] `bash tests/bacon_home_manager_migration_test.sh`
- [ ] `bash tests/wezterm_home_manager_migration_test.sh`
- [ ] `bash tests/yazi_home_manager_migration_test.sh`
- [ ] `bash tests/zsh_nix_migration_test.sh`
- [ ] Expected: PASS

### Task 9: Run Neovim regression tests against the relocated tree

**Files:**
- Check: `nix/home-manager/nvim/**`
- Test: `tests/nvim_env_test.lua`
- Test: `tests/nvim_nix_shell_support_test.lua`
- Test: `tests/nvim_typos_lsp_test.lua`
- Test: `tests/nvim_web_support_test.lua`
- Test: `tests/nvim_leetcode_test.lua`

- [ ] Run:
- [ ] `lua tests/nvim_env_test.lua`
- [ ] `lua tests/nvim_nix_shell_support_test.lua`
- [ ] `lua tests/nvim_typos_lsp_test.lua`
- [ ] `lua tests/nvim_web_support_test.lua`
- [ ] `lua tests/nvim_leetcode_test.lua`
- [ ] Expected: all PASS

### Task 10: Verify Home Manager build output

**Files:**
- Check: `nix/flake.nix`
- Check: `nix/home-manager/nvim.nix`

- [ ] Run: `home-manager build --flake nix#KokiAoyagi`
- [ ] Expected: PASS
- [ ] Inspect `result/home-files/.config/nvim`
- [ ] Inspect that PATH-visible tooling from `home.packages` is present in the built environment
- [ ] If practical, run: `nvim --headless "+qa"`
- [ ] Expected: clean exit

### Task 11: Final cleanup and commit

**Files:**
- Check: `git status`

- [ ] Confirm `.config/nvim` is removed and `nix/home-manager/nvim/**` is the only source tree
- [ ] Confirm `rustowl` and image features are marked deferred in code comments only where needed
- [ ] Review diff for accidental config changes outside migration scope
- [ ] Commit:

```bash
git add nix/home-manager/home.nix nix/home-manager/nvim.nix nix/home-manager/nvim install.sh tests/nvim_home_manager_migration_test.sh tests/nvim_env_test.lua tests/nvim_nix_shell_support_test.lua tests/nvim_typos_lsp_test.lua tests/nvim_web_support_test.lua tests/nvim_leetcode_test.lua
git commit -m "feat(nix): migrate neovim to home-manager"
```

## Unresolved questions

- None.
