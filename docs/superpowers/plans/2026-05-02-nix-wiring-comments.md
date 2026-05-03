# Nix Wiring Comments Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add explanatory comments to the current `flake.nix` and `nix-darwin` bridge files so a future reader can tell what each file is for and what kind of settings belong there, without changing Nix behavior.

**Architecture:** Update only comments in the three wiring files: `.config/nix/flake.nix`, `.config/nix/nix-darwin/configuration.nix`, and `.config/nix/nix-darwin/home_manager.nix`. Keep the comments focused on role, ownership, and future responsibility boundaries, then verify that the existing wiring tests still pass unchanged.

**Tech Stack:** Nix, shell regression tests

---

## Chunk 1: Add explanatory comments without changing behavior

### Task 1: Annotate the flake entry points

**Files:**
- Modify: `.config/nix/flake.nix:1-43`
- Test: `tests/home_manager_only_flake_test.sh`

- [ ] **Step 1: Add comments describing what belongs in `flake.nix`**

Add comments that explain:
- this file defines flake entry points
- `homeConfigurations."KokiAoyagi"` is the standalone Home Manager entry kept as a fallback/comparison path
- `darwinConfigurations."KokiAoyagi"` is the main nix-darwin entry
- `home-manager.darwinModules.home-manager` is required so nix-darwin can understand `home-manager.*` options from the imported module chain

- [ ] **Step 2: Run the wiring regression test**

Run: `bash tests/home_manager_only_flake_test.sh`  
Expected: PASS

### Task 2: Annotate the minimal `nix-darwin` bridge

**Files:**
- Modify: `.config/nix/nix-darwin/configuration.nix:1-10`
- Modify: `.config/nix/nix-darwin/home_manager.nix:1-5`
- Test: `tests/nix_darwin_reset_test.sh`

- [ ] **Step 1: Add comments to `configuration.nix`**

Add comments that explain:
- this file is the nix-darwin side's main config file
- it is currently kept intentionally minimal as a bridge
- future macOS/darwin settings such as `homebrew`, `system.defaults`, `security`, and `users` belong here
- the remaining options are still needed as darwin-side identity and revision metadata

- [ ] **Step 2: Add comments to `home_manager.nix`**

Add comments that explain:
- this file is only the connection layer from nix-darwin into the existing Home Manager tree
- actual user-facing config such as shell, git, and tmux belongs under `../home-manager/home.nix` and its imports
- `useGlobalPkgs` and `useUserPackages` are there to share the package set and allow Home Manager to install user packages through the darwin integration

- [ ] **Step 3: Re-run both regression tests**

Run: `bash tests/home_manager_only_flake_test.sh`  
Expected: PASS

Run: `bash tests/nix_darwin_reset_test.sh`  
Expected: PASS

- [ ] **Step 4: Verify only comment-only diffs landed**

Run: `git diff -- .config/nix/flake.nix .config/nix/nix-darwin/configuration.nix .config/nix/nix-darwin/home_manager.nix`  
Expected: diff changes comments only, no Nix expressions or values change

- [ ] **Step 5: Commit the comment pass**

```bash
git add .config/nix/flake.nix .config/nix/nix-darwin/configuration.nix .config/nix/nix-darwin/home_manager.nix
git commit -m "docs(nix): explain darwin and home-manager wiring"
```

Unresolved questions:
- None
