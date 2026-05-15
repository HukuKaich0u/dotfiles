# Nix Darwin/Linux Module Split Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move Nix module entrypoints under `nix/modules/**`, keep macOS on `nix-darwin`, add Linux standalone Home Manager at `homeConfigurations.kokiaoyagi`.

**Architecture:** Shared Home Manager config lives in `nix/modules/home/default.nix` plus `nix/modules/home/programs/*.nix`. macOS system config lives in `nix/modules/darwin/system.nix`, macOS user-only Home Manager deltas live in `nix/modules/darwin/default.nix`, and Linux uses `nix/modules/linux/default.nix` with standalone Home Manager on `aarch64-linux`. Keep `nix/home-manager/nvim/**`, `nix/home-manager/tmux/tmux.conf`, and `nix/home-manager/wezterm/**` in place for phase 1 and point new modules at those assets.

**Tech Stack:** Nix flakes, Home Manager, nix-darwin, shell tests, Neovim Lua tests, git

---

## Chunk 1: Path-First Test Scaffold

### Task 1: Repoint tests and docs to the new module tree

**Files:**
- Create: `nix/modules/home/default.nix`
- Create: `nix/modules/home/programs/bacon.nix`
- Create: `nix/modules/home/programs/gh.nix`
- Create: `nix/modules/home/programs/git.nix`
- Create: `nix/modules/home/programs/mise.nix`
- Create: `nix/modules/home/programs/nvim.nix`
- Create: `nix/modules/home/programs/starship.nix`
- Create: `nix/modules/home/programs/tmux.nix`
- Create: `nix/modules/home/programs/wezterm.nix`
- Create: `nix/modules/home/programs/yazi.nix`
- Create: `nix/modules/home/programs/zsh.nix`
- Create: `nix/modules/darwin/default.nix`
- Create: `nix/modules/darwin/homebrew.nix`
- Create: `nix/modules/darwin/system.nix`
- Create: `nix/modules/linux/default.nix`
- Modify: `docs/mise-guide.md`
- Modify: `tests/bacon_home_manager_migration_test.sh`
- Modify: `tests/direnv_zsh_check_skip_test.sh`
- Modify: `tests/ghconfig_paths_test.sh`
- Modify: `tests/gitconfig_paths_test.sh`
- Modify: `tests/home_manager_only_flake_test.sh`
- Modify: `tests/mise_home_manager_bootstrap_test.sh`
- Modify: `tests/nix_darwin_reset_test.sh`
- Modify: `tests/nvim_home_manager_migration_test.sh`
- Modify: `tests/tmux_nix_migration_test.sh`
- Modify: `tests/wezterm_home_manager_migration_test.sh`
- Modify: `tests/yazi_home_manager_migration_test.sh`
- Modify: `tests/zsh_nix_migration_test.sh`

- [ ] Update module-path assertions from `nix/home-manager/*.nix` to `nix/modules/home/...` and from `nix/nix-darwin/*.nix` to `nix/modules/darwin/...`.
- [ ] Keep asset-path assertions on `nix/home-manager/nvim/**`, `nix/home-manager/tmux/tmux.conf`, and `nix/home-manager/wezterm/**` unchanged.
- [ ] Update [docs/mise-guide.md](/Users/KokiAoyagi/Documents/repos/personal/dotfiles/docs/mise-guide.md:110) to point at `nix/modules/home/programs/mise.nix`.
- [ ] Run failing checks:

```bash
sh tests/home_manager_only_flake_test.sh
sh tests/ghconfig_paths_test.sh
sh tests/gitconfig_paths_test.sh
sh tests/mise_home_manager_bootstrap_test.sh
```

Expected: FAIL on missing `nix/modules/**` files or imports.

- [ ] Commit:

```bash
git add docs/mise-guide.md tests/home_manager_only_flake_test.sh tests/ghconfig_paths_test.sh tests/gitconfig_paths_test.sh tests/mise_home_manager_bootstrap_test.sh tests/bacon_home_manager_migration_test.sh tests/direnv_zsh_check_skip_test.sh tests/nix_darwin_reset_test.sh tests/nvim_home_manager_migration_test.sh tests/tmux_nix_migration_test.sh tests/wezterm_home_manager_migration_test.sh tests/yazi_home_manager_migration_test.sh tests/zsh_nix_migration_test.sh
git commit -m "test: repoint nix module path checks"
```

### Task 2: Create module scaffolds

**Files:**
- Create: `nix/modules/home/default.nix`
- Create: `nix/modules/home/programs/bacon.nix`
- Create: `nix/modules/home/programs/gh.nix`
- Create: `nix/modules/home/programs/git.nix`
- Create: `nix/modules/home/programs/mise.nix`
- Create: `nix/modules/home/programs/nvim.nix`
- Create: `nix/modules/home/programs/starship.nix`
- Create: `nix/modules/home/programs/tmux.nix`
- Create: `nix/modules/home/programs/wezterm.nix`
- Create: `nix/modules/home/programs/yazi.nix`
- Create: `nix/modules/home/programs/zsh.nix`
- Create: `nix/modules/darwin/default.nix`
- Create: `nix/modules/darwin/homebrew.nix`
- Create: `nix/modules/darwin/system.nix`
- Create: `nix/modules/linux/default.nix`

- [ ] Create `nix/modules/home/programs`, `nix/modules/darwin`, and `nix/modules/linux`.
- [ ] Add parseable placeholder modules so the repointed tests can reach content assertions.
- [ ] Re-run:

```bash
sh tests/home_manager_only_flake_test.sh
sh tests/ghconfig_paths_test.sh
sh tests/gitconfig_paths_test.sh
sh tests/mise_home_manager_bootstrap_test.sh
```

Expected: still FAIL, but now on missing content rather than missing files.

- [ ] Commit:

```bash
git add nix/modules
git commit -m "chore(nix): scaffold module tree"
```

## Chunk 2: Shared Home Manager Migration

### Task 3: Move the shared Home Manager root

**Files:**
- Modify: `nix/modules/home/default.nix`

- [ ] Port `nix/home-manager/home.nix` into `nix/modules/home/default.nix`.
- [ ] Make the module take `username`, `homeDirectory`, and `system` via `extraSpecialArgs`.
- [ ] Set `home.username = username;`, `home.homeDirectory = homeDirectory;`, `home.stateVersion = "25.11";`, and `programs.home-manager.enable = true;`.
- [ ] Keep only cross-platform packages in `home.packages`: `git`, `ripgrep`, `fd`, `gnumake`, `tmux`, `lazygit`, `imagemagick`.
- [ ] Remove `pngpaste` and `ascii-image-converter` from the shared root.

### Task 4: Move the shared program modules

**Files:**
- Modify: `docs/mise-guide.md`
- Modify: `nix/modules/home/programs/bacon.nix`
- Modify: `nix/modules/home/programs/gh.nix`
- Modify: `nix/modules/home/programs/git.nix`
- Modify: `nix/modules/home/programs/mise.nix`
- Modify: `nix/modules/home/programs/nvim.nix`
- Modify: `nix/modules/home/programs/starship.nix`
- Modify: `nix/modules/home/programs/tmux.nix`
- Modify: `nix/modules/home/programs/wezterm.nix`
- Modify: `nix/modules/home/programs/yazi.nix`
- Modify: `nix/modules/home/programs/zsh.nix`

- [ ] Copy each `nix/home-manager/*.nix` body into the matching `nix/modules/home/programs/*.nix`.
- [ ] Keep behavior unchanged unless the new path requires a fix.
- [ ] Update relative asset paths:
  `nix/modules/home/programs/nvim.nix` -> `../../../home-manager/nvim`
  `nix/modules/home/programs/tmux.nix` -> `../../../home-manager/tmux/tmux.conf`
  `nix/modules/home/programs/wezterm.nix` -> `../../../home-manager/wezterm/wezterm.lua`
  `nix/modules/home/programs/wezterm.nix` -> `../../../home-manager/wezterm/keybinds.lua`
- [ ] Leave `zsh.nix` logic intact for phase 1; do not split its darwin PATH block yet.
- [ ] Re-run shared-module checks:

```bash
sh tests/ghconfig_paths_test.sh
sh tests/gitconfig_paths_test.sh
sh tests/mise_home_manager_bootstrap_test.sh
sh tests/bacon_home_manager_migration_test.sh
sh tests/yazi_home_manager_migration_test.sh
sh tests/wezterm_home_manager_migration_test.sh
sh tests/nvim_home_manager_migration_test.sh
sh tests/tmux_nix_migration_test.sh
sh tests/zsh_nix_migration_test.sh
```

Expected: PASS.

- [ ] Commit:

```bash
git add docs/mise-guide.md nix/modules/home
git commit -m "refactor(nix): move shared home-manager modules"
```

## Chunk 3: Darwin/Linux Wiring

### Task 5: Rewrite flake entrypoints and platform modules

**Files:**
- Modify: `nix/flake.nix`
- Modify: `nix/modules/darwin/default.nix`
- Modify: `nix/modules/darwin/homebrew.nix`
- Modify: `nix/modules/darwin/system.nix`
- Modify: `nix/modules/linux/default.nix`

- [ ] In `nix/flake.nix`, define:

```nix
commonNixpkgs = import ./common/nixpkgs.nix;
mkPkgs = system: import nixpkgs {
  inherit system;
  config = commonNixpkgs.nixpkgs.config;
  overlays = commonNixpkgs.nixpkgs.overlays;
};
darwinUsername = "KokiAoyagi";
darwinHomeDirectory = "/Users/KokiAoyagi";
linuxUsername = "kokiaoyagi";
linuxHomeDirectory = "/home/kokiaoyagi";
```

- [ ] Replace `homeConfigurations."KokiAoyagi"` with `homeConfigurations."kokiaoyagi"` on `aarch64-linux`.
- [ ] Wire Linux Home Manager to import `nix/modules/home/default.nix` and `nix/modules/linux/default.nix`.
- [ ] Replace the old darwin entry so `darwinConfigurations."KokiAoyagi"` imports `nix/modules/darwin/system.nix`, `home-manager.darwinModules.home-manager`, and inline Home Manager user wiring for:
  `nix/modules/home/default.nix`
  `nix/modules/darwin/default.nix`
- [ ] Move existing machine-level darwin settings into `nix/modules/darwin/system.nix`.
- [ ] Move the existing Homebrew lists into `nix/modules/darwin/homebrew.nix`.
- [ ] Put darwin-only Home Manager packages in `nix/modules/darwin/default.nix`: `pngpaste`, `pkgs."ascii-image-converter"`.
- [ ] Keep `nix/common/nixpkgs.nix` as the shared allow-unfree + overlay source.
- [ ] Run wiring checks:

```bash
sh tests/home_manager_only_flake_test.sh
sh tests/nix_darwin_reset_test.sh
sh tests/direnv_zsh_check_skip_test.sh
nix eval ./nix#darwinConfigurations.KokiAoyagi.system.primaryUser --raw
nix eval ./nix#homeConfigurations.kokiaoyagi.config.home.username --raw
```

Expected: shell tests PASS, eval returns `KokiAoyagi` and `kokiaoyagi`.

- [ ] Commit:

```bash
git add nix/flake.nix nix/modules/darwin nix/modules/linux
git commit -m "feat(nix): split darwin and linux flake entrypoints"
```

## Chunk 4: Cleanup And Verification

### Task 6: Remove obsolete module entry files

**Files:**
- Delete: `nix/home-manager/bacon.nix`
- Delete: `nix/home-manager/gh.nix`
- Delete: `nix/home-manager/git.nix`
- Delete: `nix/home-manager/home.nix`
- Delete: `nix/home-manager/mise.nix`
- Delete: `nix/home-manager/nvim.nix`
- Delete: `nix/home-manager/starship.nix`
- Delete: `nix/home-manager/tmux.nix`
- Delete: `nix/home-manager/wezterm.nix`
- Delete: `nix/home-manager/yazi.nix`
- Delete: `nix/home-manager/zsh.nix`
- Delete: `nix/nix-darwin/configuration.nix`
- Delete: `nix/nix-darwin/home_manager.nix`
- Delete: `nix/nix-darwin/homebrew.nix`

- [ ] Delete only the old module entry files; keep asset trees under `nix/home-manager/nvim`, `nix/home-manager/tmux`, and `nix/home-manager/wezterm`.
- [ ] Run:

```bash
rg -n 'nix/home-manager/(home|[^/]+\\.nix)|nix/nix-darwin/' docs tests nix -g '!docs/superpowers/**'
```

Expected: no hits except allowed asset-tree paths under `nix/home-manager/nvim`, `nix/home-manager/tmux`, and `nix/home-manager/wezterm`.

### Task 7: Full verification

**Files:**
- Check: `docs/mise-guide.md`
- Check: `nix/flake.nix`
- Check: `nix/modules/home/default.nix`
- Check: `nix/modules/home/programs/*.nix`
- Check: `nix/modules/darwin/*.nix`
- Check: `nix/modules/linux/default.nix`
- Check: `tests/*.sh`
- Check: `tests/*.lua`

- [ ] Run all shell regressions:

```bash
sh tests/install_dotfiles_test.sh
sh tests/ghconfig_paths_test.sh
sh tests/gitconfig_paths_test.sh
sh tests/home_manager_only_flake_test.sh
sh tests/mise_home_manager_bootstrap_test.sh
sh tests/nix_darwin_reset_test.sh
sh tests/bacon_home_manager_migration_test.sh
sh tests/yazi_home_manager_migration_test.sh
sh tests/wezterm_home_manager_migration_test.sh
sh tests/nvim_home_manager_migration_test.sh
sh tests/tmux_nix_migration_test.sh
sh tests/zsh_nix_migration_test.sh
sh tests/direnv_zsh_check_skip_test.sh
```

Expected: PASS.

- [ ] Run Neovim Lua regressions:

```bash
nvim --headless -u NONE -l tests/nvim_env_test.lua
nvim --headless -u NONE -l tests/nvim_nix_shell_support_test.lua
nvim --headless -u NONE -l tests/nvim_typos_lsp_test.lua
nvim --headless -u NONE -l tests/nvim_web_support_test.lua
nvim --headless -u NONE -l tests/nvim_leetcode_test.lua
```

Expected: PASS.

- [ ] Run Linux Home Manager build:

```bash
home-manager build --flake ./nix#kokiaoyagi
```

Expected: PASS on `aarch64-linux`.

- [ ] Run direct activation-package build if `home-manager` CLI is unavailable:

```bash
nix build ./nix#homeConfigurations.kokiaoyagi.activationPackage
```

Expected: PASS.

- [ ] Commit:

```bash
git add nix docs/mise-guide.md tests
git commit -m "refactor(nix): split darwin and linux module trees"
```

## Unresolved Questions

- None.
