# Home Manager CLI Migration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `bacon`, `wezterm` config, and `nvim` into Home Manager in stages while keeping `wezterm` app ownership in Homebrew and minimizing behavior changes.

**Architecture:** Add one Home Manager module per tool under `.config/nix/home-manager`, following the existing per-program structure. For `bacon`, prefer native Home Manager options; for `wezterm` and `nvim`, move the config source tree under the Home Manager directory and wire it with `xdg.configFile`, then stop `install.sh` from linking those paths.

**Tech Stack:** Nix, Home Manager, nix-darwin, Homebrew casks, shell regression tests, existing `install.sh`

---

## Chunk 1: `bacon` migration

### Task 1: Lock the migration shape with a failing test

**Files:**
- Create: `tests/bacon_home_manager_migration_test.sh`
- Check: `.config/nix/home-manager/home.nix`
- Check: `.config/nix/home-manager/bacon.nix`
- Check: `install.sh`

- [ ] Step 1: Write failing test for `./bacon.nix` import, `programs.bacon`, expected settings keys, `install.sh` skip, and removal of `.config/bacon/prefs.toml` as symlink-managed source.
- [ ] Step 2: Run `bash tests/bacon_home_manager_migration_test.sh`; expect FAIL because module and skip wiring do not exist yet.
- [ ] Step 3: Commit failing test.

### Task 2: Implement `bacon` through Home Manager options

**Files:**
- Create: `.config/nix/home-manager/bacon.nix`
- Modify: `.config/nix/home-manager/home.nix`
- Modify: `install.sh`
- Remove or relocate source from: `.config/bacon/prefs.toml`
- Test: `tests/bacon_home_manager_migration_test.sh`

- [ ] Step 1: Add `programs.bacon.enable = true;`.
- [ ] Step 2: Translate current `prefs.toml` into `programs.bacon.settings`, including `listen` and `exports.locations`.
- [ ] Step 3: Import `./bacon.nix` from `home.nix`.
- [ ] Step 4: Add `bacon` to `SKIP_CONFIG_DIRS`.
- [ ] Step 5: Remove the old repo-managed `prefs.toml` source once the Nix module owns it.
- [ ] Step 6: Run `bash tests/bacon_home_manager_migration_test.sh`; expect PASS.
- [ ] Step 7: Commit implementation.

### Task 3: Verify generated output

**Files:**
- Check: `.config/nix/flake.nix`
- Check: `.config/nix/home-manager/bacon.nix`

- [ ] Step 1: Run `home-manager build --flake .config/nix#KokiAoyagi`; expect PASS.
- [ ] Step 2: Inspect generated bacon config under `result/home-files/.config`.
- [ ] Step 3: Confirm generated content matches current `listen` and `exports.locations` values.

## Chunk 2: `wezterm` config migration

### Task 4: Lock the migration shape with a failing test

**Files:**
- Create: `tests/wezterm_home_manager_migration_test.sh`
- Check: `.config/nix/home-manager/home.nix`
- Check: `.config/nix/home-manager/wezterm.nix`
- Check: `.config/nix/nix-darwin/homebrew.nix`
- Check: `install.sh`

- [ ] Step 1: Write failing test for `./wezterm.nix` import, `xdg.configFile` wiring, Home Manager-managed `wezterm.lua` and `keybinds.lua`, `install.sh` skip, and continued Homebrew ownership of the app if casks are declared here.
- [ ] Step 2: Run `bash tests/wezterm_home_manager_migration_test.sh`; expect FAIL because wiring does not exist yet.
- [ ] Step 3: Commit failing test.

### Task 5: Move `wezterm` config under Home Manager

**Files:**
- Create: `.config/nix/home-manager/wezterm.nix`
- Create: `.config/nix/home-manager/wezterm/wezterm.lua`
- Create: `.config/nix/home-manager/wezterm/keybinds.lua`
- Modify: `.config/nix/home-manager/home.nix`
- Modify: `install.sh`
- Remove or relocate source from: `.config/wezterm/wezterm.lua`, `.config/wezterm/keybinds.lua`
- Test: `tests/wezterm_home_manager_migration_test.sh`

- [ ] Step 1: Copy the existing Lua files into the Home Manager tree without semantic changes.
- [ ] Step 2: Wire both files with `xdg.configFile` in `wezterm.nix`.
- [ ] Step 3: Import `./wezterm.nix` from `home.nix`.
- [ ] Step 4: Add `wezterm` to `SKIP_CONFIG_DIRS`.
- [ ] Step 5: Remove the old repo-managed `.config/wezterm` source once the module owns it.
- [ ] Step 6: Run `bash tests/wezterm_home_manager_migration_test.sh`; expect PASS.
- [ ] Step 7: Commit implementation.

### Task 6: Verify generated output

**Files:**
- Check: `.config/nix/home-manager/wezterm.nix`
- Check: `.config/nix/nix-darwin/homebrew.nix`

- [ ] Step 1: Run `home-manager build --flake .config/nix#KokiAoyagi`; expect PASS.
- [ ] Step 2: Inspect `result/home-files/.config/wezterm/wezterm.lua` and `keybinds.lua`.
- [ ] Step 3: Confirm `homebrew.nix` still reflects the intended `wezterm` app ownership model.

## Chunk 3: `nvim` migration

### Task 7: Lock the migration shape with a failing test

**Files:**
- Create: `tests/neovim_home_manager_migration_test.sh`
- Check: `.config/nix/home-manager/home.nix`
- Check: `.config/nix/home-manager/neovim.nix`
- Check: `install.sh`

- [ ] Step 1: Write failing test for `./neovim.nix` import, `programs.neovim.enable = true;`, `xdg.configFile."nvim"` wiring, `install.sh` skip, and removal of `.config/nvim` as symlink-managed source.
- [ ] Step 2: Run `bash tests/neovim_home_manager_migration_test.sh`; expect FAIL because module and skip wiring do not exist yet.
- [ ] Step 3: Commit failing test.

### Task 8: Move `nvim` under Home Manager

**Files:**
- Create: `.config/nix/home-manager/neovim.nix`
- Create: `.config/nix/home-manager/nvim/` (mirror current Neovim config tree)
- Modify: `.config/nix/home-manager/home.nix`
- Modify: `install.sh`
- Remove or relocate source from: `.config/nvim/**`
- Test: `tests/neovim_home_manager_migration_test.sh`
- Regression checks: `tests/nvim_env_test.lua`, `tests/nvim_nix_shell_support_test.lua`, `tests/nvim_typos_lsp_test.lua`, `tests/nvim_web_support_test.lua`, `tests/nvim_leetcode_test.lua`

- [ ] Step 1: Copy the current Neovim config tree under `.config/nix/home-manager/nvim/`.
- [ ] Step 2: Add `programs.neovim.enable = true;`.
- [ ] Step 3: Wire the config directory with `xdg.configFile."nvim".source = ./nvim`.
- [ ] Step 4: Import `./neovim.nix` from `home.nix`.
- [ ] Step 5: Add `nvim` to `SKIP_CONFIG_DIRS`.
- [ ] Step 6: Remove the old repo-managed `.config/nvim` source once the module owns it.
- [ ] Step 7: Run `bash tests/neovim_home_manager_migration_test.sh`; expect PASS.
- [ ] Step 8: Run the existing Neovim regression tests that do not require expanding scope beyond this migration.
- [ ] Step 9: Commit implementation.

### Task 9: Verify generated output

**Files:**
- Check: `.config/nix/home-manager/neovim.nix`
- Check: `.config/nix/home-manager/nvim/**`

- [ ] Step 1: Run `home-manager build --flake .config/nix#KokiAoyagi`; expect PASS.
- [ ] Step 2: Inspect `result/home-files/.config/nvim`.
- [ ] Step 3: Launch a minimal validation such as `nvim --headless "+qa"` in the configured environment if practical.
- [ ] Step 4: Record any remaining runtime dependencies that are still outside Home Manager as follow-up work, not part of this migration.

## Unresolved questions

- None.
