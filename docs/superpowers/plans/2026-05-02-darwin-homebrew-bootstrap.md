# darwin Homebrew Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dedicated `homebrew.nix` module under `nix-darwin`, wire it into `configuration.nix`, and verify that `homebrew.enable = true;` is visible through the darwin flake entry without applying the config.

**Architecture:** First extend the existing `nix_darwin_reset_test.sh` contract so the minimal darwin bridge now expects a `homebrew.nix` import plus a new module containing only `homebrew.enable = true;`. Then add the module, import it from `configuration.nix`, and confirm the wiring with the updated regression test and a focused `nix eval` on the darwin flake output.

**Tech Stack:** Nix, shell regression test, `nix eval`

---

## Chunk 1: Lock the Homebrew bootstrap contract

### Task 1: Update the darwin reset regression test first

**Files:**
- Modify: `tests/nix_darwin_reset_test.sh:1-53`
- Check: `.config/nix/nix-darwin/configuration.nix:1-23`
- Check: `.config/nix/nix-darwin/home_manager.nix`
- Check: `.config/nix/nix-darwin/homebrew.nix`

- [ ] **Step 1: Extend the test to expect the Homebrew bootstrap module**

Add assertions that:
- `configuration.nix` still imports `./home_manager.nix`
- `configuration.nix` also imports `./homebrew.nix`
- `.config/nix/nix-darwin/homebrew.nix` exists
- `homebrew.nix` contains `homebrew.enable = true;`

- [ ] **Step 2: Run the test to verify it fails**

Run: `bash tests/nix_darwin_reset_test.sh`  
Expected: FAIL because `configuration.nix` does not import `./homebrew.nix` yet and `homebrew.nix` does not exist yet

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/nix_darwin_reset_test.sh
git commit -m "test: cover darwin homebrew bootstrap"
```

## Chunk 2: Add the dedicated Homebrew module

### Task 2: Create `homebrew.nix` and wire it into `configuration.nix`

**Files:**
- Create: `.config/nix/nix-darwin/homebrew.nix`
- Modify: `.config/nix/nix-darwin/configuration.nix:18-22`
- Test: `tests/nix_darwin_reset_test.sh`

- [ ] **Step 1: Create the minimal Homebrew module**

```nix
{
  homebrew.enable = true;
}
```

- [ ] **Step 2: Import the module from `configuration.nix`**

Add `./homebrew.nix` to the existing `imports` list, keeping `./home_manager.nix` in place.

- [ ] **Step 3: Re-run the regression test**

Run: `bash tests/nix_darwin_reset_test.sh`  
Expected: PASS

- [ ] **Step 4: Verify the darwin flake entry exposes the enabled flag**

Run: `nix eval .config/nix#darwinConfigurations.KokiAoyagi.config.homebrew.enable --raw`  
Expected: `true`

- [ ] **Step 5: Verify only the intended files changed**

Run: `git diff -- .config/nix/nix-darwin/configuration.nix .config/nix/nix-darwin/homebrew.nix tests/nix_darwin_reset_test.sh`  
Expected: diff shows the new Homebrew module, the new import, and the updated regression test only

- [ ] **Step 6: Commit the bootstrap wiring**

```bash
git add .config/nix/nix-darwin/configuration.nix .config/nix/nix-darwin/homebrew.nix tests/nix_darwin_reset_test.sh
git commit -m "feat(nix-darwin): bootstrap homebrew module"
```

Unresolved questions:
- None
