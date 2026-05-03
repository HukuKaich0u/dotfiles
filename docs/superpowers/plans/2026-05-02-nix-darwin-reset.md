# nix-darwin Reset Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Leave `home-manager` untouched and reduce `nix-darwin` to the minimum config that only wires in `home_manager.nix`, without applying the change.

**Architecture:** Add one focused regression test that defines the desired minimal `configuration.nix` shape, then trim `.config/nix/nix-darwin/configuration.nix` to only the required fields and stop at diff review. Do not run `darwin-rebuild`, `home-manager switch`, or any apply step in this plan.

**Tech Stack:** Nix, shell regression test, git diff

---

## Chunk 1: Lock expected minimal shape

### Task 1: Add a failing regression test

**Files:**
- Create: `tests/nix_darwin_reset_test.sh`
- Check: `.config/nix/nix-darwin/configuration.nix:1-63`
- Check: `.config/nix/nix-darwin/home_manager.nix:1-5`

- [ ] **Step 1: Write the failing test**

```bash
#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
config_nix="$repo_root/.config/nix/nix-darwin/configuration.nix"
home_manager_nix="$repo_root/.config/nix/nix-darwin/home_manager.nix"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"
  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_not_contains() {
  file="$1"
  needle="$2"
  message="$3"
  if grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$config_nix" 'system.stateVersion = 6;' \
  "configuration.nix must keep system.stateVersion"
assert_contains "$config_nix" 'system.configurationRevision = self.rev or self.dirtyRev or null;' \
  "configuration.nix must keep system.configurationRevision"
assert_contains "$config_nix" 'system.primaryUser = "KokiAoyagi";' \
  "configuration.nix must keep system.primaryUser"
assert_contains "$config_nix" 'users.users.KokiAoyagi.home = "/Users/KokiAoyagi";' \
  "configuration.nix must keep the user home path"
assert_contains "$config_nix" './home_manager.nix' \
  "configuration.nix must keep the home_manager import"

assert_not_contains "$config_nix" '../common/nixpkgs.nix' \
  "configuration.nix must remove the common nixpkgs import"
assert_not_contains "$config_nix" 'nix.enable = false;' \
  "configuration.nix must remove nix.enable"
assert_not_contains "$config_nix" 'system.defaults =' \
  "configuration.nix must remove macOS defaults"
assert_not_contains "$config_nix" 'nixpkgs.hostPlatform' \
  "configuration.nix must remove hostPlatform"
assert_not_contains "$config_nix" 'security.pam.services.sudo_local.touchIdAuth' \
  "configuration.nix must remove Touch ID sudo config"

assert_contains "$home_manager_nix" 'home-manager.users."KokiAoyagi" = ../home-manager/home.nix;' \
  "home_manager.nix must stay wired to home-manager/home.nix"

echo "nix-darwin reset test passed"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/nix_darwin_reset_test.sh`  
Expected: FAIL because `configuration.nix` still contains removed `nix-darwin` settings

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/nix_darwin_reset_test.sh
git commit -m "test: cover minimal nix-darwin reset"
```

## Chunk 2: Trim `configuration.nix` and stop at review

### Task 2: Reduce `nix-darwin` to the Home Manager bridge

**Files:**
- Modify: `.config/nix/nix-darwin/configuration.nix:1-63`
- Check: `.config/nix/nix-darwin/home_manager.nix:1-5`
- Test: `tests/nix_darwin_reset_test.sh`

- [ ] **Step 1: Replace `configuration.nix` with the minimal shape**

```nix
{self, ...}: {
  system.stateVersion = 6;
  system.configurationRevision = self.rev or self.dirtyRev or null;
  system.primaryUser = "KokiAoyagi";
  users.users.KokiAoyagi.home = "/Users/KokiAoyagi";

  imports = [
    ./home_manager.nix
  ];
}
```

- [ ] **Step 2: Re-run the regression test**

Run: `bash tests/nix_darwin_reset_test.sh`  
Expected: PASS

- [ ] **Step 3: Verify only intended files changed**

Run: `git diff -- .config/nix/nix-darwin/configuration.nix .config/nix/nix-darwin/home_manager.nix tests/nix_darwin_reset_test.sh`  
Expected: diff shows `configuration.nix` trimmed, new test added, `home_manager.nix` unchanged

- [ ] **Step 4: Verify no apply step was run**

Run: `git status --short`  
Expected: only working tree changes for the reviewed files; no generated `result` symlink, no rebuild artifacts

- [ ] **Step 5: Commit the reviewable diff**

```bash
git add .config/nix/nix-darwin/configuration.nix tests/nix_darwin_reset_test.sh
git commit -m "refactor(nix-darwin): reset to minimal home-manager bridge"
```

Unresolved questions:
- None
