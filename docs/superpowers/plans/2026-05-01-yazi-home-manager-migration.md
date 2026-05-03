# yazi Home Manager Migration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `yazi` package and the existing `yazi.toml` settings into Home Manager without adding shell integration or changing current behavior.

**Architecture:** Add a dedicated `.config/nix/home-manager/yazi.nix` module and import it from `home.nix`, following the existing per-program Home Manager structure in this repo. Convert the current `.config/yazi/yazi.toml` into `programs.yazi.settings`, then remove the old symlink-based source of truth and cover the migration with a focused shell regression test plus a Home Manager build.

**Tech Stack:** Nix, Home Manager, shell regression tests, existing `install.sh`

---

## Chunk 1: Regression coverage for the migration shape

### Task 1: Add a focused yazi migration regression test

**Files:**
- Create: `tests/yazi_home_manager_migration_test.sh`
- Check: `.config/nix/home-manager/home.nix`
- Check: `.config/nix/home-manager/yazi.nix`
- Check: `install.sh`

- [ ] **Step 1: Write the failing test**

```bash
#!/bin/sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
home_nix="$repo_root/.config/nix/home-manager/home.nix"
yazi_nix="$repo_root/.config/nix/home-manager/yazi.nix"
install_sh="$repo_root/install.sh"

assert_contains() {
  file="$1"
  needle="$2"
  message="$3"
  if ! grep -Fq "$needle" "$file"; then
    echo "$message"
    exit 1
  fi
}

assert_not_exists() {
  path="$1"
  message="$2"
  if [ -e "$path" ]; then
    echo "$message"
    exit 1
  fi
}

assert_contains "$home_nix" './yazi.nix' \
  "home-manager should import yazi.nix"
assert_contains "$yazi_nix" 'programs.yazi = {' \
  "yazi.nix should enable programs.yazi"
assert_contains "$install_sh" 'SKIP_CONFIG_DIRS="tmux zsh starship.toml yazi"' \
  "install.sh should skip yazi after home-manager migration"
assert_not_exists "$repo_root/.config/yazi/yazi.toml" \
  "legacy yazi.toml should be removed from the symlink-managed config tree"

echo "yazi home-manager migration test passed"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash tests/yazi_home_manager_migration_test.sh`
Expected: FAIL because `yazi.nix` does not exist yet and `install.sh` still links `.config/yazi`

- [ ] **Step 3: Commit the failing test**

```bash
git add tests/yazi_home_manager_migration_test.sh
git commit -m "test: cover yazi home-manager migration"
```

## Chunk 2: Home Manager wiring and legacy cleanup

### Task 2: Add the Home Manager yazi module

**Files:**
- Create: `.config/nix/home-manager/yazi.nix`
- Modify: `.config/nix/home-manager/home.nix`
- Check: `.config/yazi/yazi.toml`

- [ ] **Step 1: Write the minimal Home Manager module**

```nix
{
  programs.yazi = {
    enable = true;
    settings = {
      mgr = {
        ratio = [ 1 4 3 ];
        sort_by = "natural";
        sort_sensitive = false;
        sort_reverse = false;
        sort_dir_first = true;
        linemode = "size";
        show_hidden = true;
        show_symlink = true;
        scrolloff = 5;
      };
      preview = {
        wrap = "yes";
        tab_size = 2;
      };
    };
  };
}
```

- [ ] **Step 2: Import the module**

Run: `sed -n '1,80p' .config/nix/home-manager/home.nix`
Expected: `imports` includes `./yazi.nix` in the existing list

- [ ] **Step 3: Remove the legacy symlink-managed config**

Run: `rm` is not needed in the plan text; instead, delete `.config/yazi/yazi.toml` through a normal patch edit and update `install.sh` so `SKIP_CONFIG_DIRS` includes `yazi`
Expected: repo no longer treats `.config/yazi` as runtime source of truth

- [ ] **Step 4: Run the regression test**

Run: `bash tests/yazi_home_manager_migration_test.sh`
Expected: PASS

- [ ] **Step 5: Commit the wiring change**

```bash
git add .config/nix/home-manager/home.nix .config/nix/home-manager/yazi.nix install.sh tests/yazi_home_manager_migration_test.sh .config/yazi/yazi.toml
git commit -m "feat(nix): manage yazi with home-manager"
```

### Task 3: Verify Home Manager output

**Files:**
- Check: `.config/nix/flake.nix`
- Check: `.config/nix/home-manager/yazi.nix`
- Test: `tests/yazi_home_manager_migration_test.sh`

- [ ] **Step 1: Build the Home Manager configuration**

Run: `home-manager build --flake .config/nix#KokiAoyagi`
Expected: PASS and produce a new `result` generation

- [ ] **Step 2: Inspect the generated yazi config**

Run: `find result/home-files/.config/yazi -maxdepth 1 -type f | sort`
Expected: includes `result/home-files/.config/yazi/yazi.toml`

- [ ] **Step 3: Check the generated values**

Run: `sed -n '1,160p' result/home-files/.config/yazi/yazi.toml`
Expected: generated TOML contains the `mgr` and `preview` values from the old config

- [ ] **Step 4: Commit if verification forced follow-up fixes**

```bash
git add .config/nix/home-manager/yazi.nix tests/yazi_home_manager_migration_test.sh install.sh .config/nix/home-manager/home.nix
git commit -m "fix(nix): align yazi home-manager output"
```

Plan complete and saved to `docs/superpowers/plans/2026-05-01-yazi-home-manager-migration.md`. Ready to execute?
