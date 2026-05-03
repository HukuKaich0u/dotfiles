# mise Home Manager Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `mise` to Home Manager through a dedicated module so the binary is Nix-managed without adding hooks or runtime config yet.

**Architecture:** Add a new `.config/nix/home-manager/mise.nix` that owns only `programs.mise.enable = true;`, then import it from `home.nix`. Prove the wiring with a focused shell regression test plus `nix eval` and `home-manager build`.

**Tech Stack:** Nix, Home Manager, shell regression test

---

## Chunk 1: Bootstrap `mise` package management

### Task 1: Add a focused regression test first

**Files:**
- Create: `tests/mise_home_manager_bootstrap_test.sh`
- Check: `.config/nix/home-manager/home.nix`
- Check: `.config/nix/home-manager/mise.nix`

- [ ] **Step 1: Write the failing test**

```bash
#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
mise_nix="$repo_root/.config/nix/home-manager/mise.nix"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"
  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$home_nix" './mise.nix' \
  "home-manager should import mise.nix"
assert_contains "$mise_nix" 'programs.mise.enable = true;' \
  "mise.nix should enable programs.mise"

echo "mise home-manager bootstrap test passed"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/mise_home_manager_bootstrap_test.sh`
Expected: FAIL because `mise.nix` does not exist yet and `home.nix` does not import it

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/mise_home_manager_bootstrap_test.sh
git commit -m "test: cover mise home-manager bootstrap"
```

### Task 2: Wire `mise` into Home Manager

**Files:**
- Create: `.config/nix/home-manager/mise.nix`
- Modify: `.config/nix/home-manager/home.nix`
- Test: `tests/mise_home_manager_bootstrap_test.sh`

- [ ] **Step 1: Add the minimal module**

```nix
{
  programs.mise.enable = true;
}
```

- [ ] **Step 2: Import the module**

Run: `sed -n '1,40p' .config/nix/home-manager/home.nix`
Expected: `imports` includes `./mise.nix`

- [ ] **Step 3: Re-run the regression test**

Run: `bash tests/mise_home_manager_bootstrap_test.sh`
Expected: PASS

- [ ] **Step 4: Verify the evaluated option**

Run: `nix eval .config/nix#homeConfigurations.KokiAoyagi.config.programs.mise.enable --raw`
Expected: `true`

- [ ] **Step 5: Verify the Home Manager build**

Run: `home-manager build --flake .config/nix#KokiAoyagi`
Expected: PASS and produce a new `result`

- [ ] **Step 6: Commit the wiring**

```bash
git add .config/nix/home-manager/home.nix .config/nix/home-manager/mise.nix tests/mise_home_manager_bootstrap_test.sh
git commit -m "feat(nix): manage mise with home-manager"
```

Unresolved questions:
- None
