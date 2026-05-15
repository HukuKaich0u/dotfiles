# Nix SoT Structure Refactor Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor `nix/` to match `nix/README.md` by moving live config into `modules/`, `overlays/`, and `lib/`.

**Architecture:** `flake.nix` stays as entry wiring only. Shared Home Manager config moves into `modules/home`, macOS machine and bridge config moves into `modules/darwin`, Linux wrapper moves into `modules/linux`, and overlay / nixpkgs helpers move into `overlays/` and `lib/`. Neovim, tmux, and WezTerm assets move under `modules/home/assets`.

**Tech Stack:** Nix flakes, Home Manager, nix-darwin, shell tests, Lua tests

---

## Chunk 1: Red Path Tests

### Task 1: Repoint tests and docs to canonical paths

**Files:**
- Modify: `docs/mise-guide.md`
- Modify: `tests/*.sh`
- Modify: `tests/*.lua`

- [ ] Rewrite path assertions from `nix/home-manager/**` and `nix/nix-darwin/**` to `nix/modules/**`, `nix/overlays/**`, and `nix/lib/**`.
- [ ] Update Neovim Lua tests to read from `nix/modules/home/assets/nvim/**`.
- [ ] Run targeted checks and confirm FAIL on missing canonical files.

## Chunk 2: Move Modules

### Task 2: Create canonical tree and move live files

**Files:**
- Create: `nix/lib/nixpkgs.nix`
- Create: `nix/overlays/default.nix`
- Create: `nix/overlays/direnv-no-zsh-check.nix`
- Create: `nix/modules/home/default.nix`
- Create: `nix/modules/home/packages.nix`
- Create: `nix/modules/home/programs/*.nix`
- Create: `nix/modules/home/assets/{nvim,tmux,wezterm}/**`
- Create: `nix/modules/darwin/{default,packages,system,home-manager,homebrew}.nix`
- Create: `nix/modules/linux/{default,packages}.nix`

- [ ] Split shared packages out of the current shared root into `modules/home/packages.nix`.
- [ ] Move program modules into `modules/home/programs/`.
- [ ] Move asset directories into `modules/home/assets/`.
- [ ] Move darwin bridge / system / homebrew into `modules/darwin/`.
- [ ] Move overlay and nixpkgs helper into `overlays/` and `lib/`.
- [ ] Re-run module-level shell tests and Lua tests until PASS.

## Chunk 3: Rewire Flake

### Task 3: Point flake entrypoints at canonical modules

**Files:**
- Modify: `nix/flake.nix`

- [ ] Use `lib/nixpkgs.nix` and `overlays/default.nix` for shared nixpkgs wiring.
- [ ] Point Linux standalone Home Manager at `modules/home/default.nix` + `modules/linux/default.nix`.
- [ ] Point nix-darwin at `modules/darwin/system.nix`.
- [ ] Verify both entrypoints with shell tests and `nix eval`.

## Chunk 4: Remove Old Tree And Verify

### Task 4: Delete migrated paths and run full verification

**Files:**
- Delete: `nix/common/**`
- Delete: `nix/home-manager/**`
- Delete: `nix/nix-darwin/**`

- [ ] Remove old paths once all references are updated.
- [ ] Run full shell regression suite plus relevant Lua tests.
- [ ] Confirm `rg` finds no lingering live references to the old tree outside historical docs/plans/specs.

## Unresolved Questions

- None.
