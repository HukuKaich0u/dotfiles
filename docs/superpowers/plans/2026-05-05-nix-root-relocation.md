# Nix Root Relocation Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the repository Nix tree from `.config/nix` to `nix/` while keeping Home Manager evaluation working and updating only runtime-relevant references.

**Architecture:** First update the path-based shell tests so they define the new `nix/` contract, then move the Nix tree in one filesystem rename and fix the practical command references that still point at `.config/nix#...`. Add targeted cleanup for stale `~/.config/nix` symlinks in `install.sh`, and verify the migration with the updated regression tests plus `home-manager build --flake ./nix#KokiAoyagi`.

**Tech Stack:** Nix, Home Manager, nix-darwin, shell regression tests, existing `install.sh`

---

## Chunk 1: Lock the new repository path contract

### Task 1: Rewrite path-based tests to expect `nix/`

**Files:**
- Modify: `tests/bacon_home_manager_migration_test.sh`
- Modify: `tests/direnv_zsh_check_skip_test.sh`
- Modify: `tests/ghconfig_paths_test.sh`
- Modify: `tests/gitconfig_paths_test.sh`
- Modify: `tests/home_manager_only_flake_test.sh`
- Modify: `tests/mise_home_manager_bootstrap_test.sh`
- Modify: `tests/nix_darwin_reset_test.sh`
- Modify: `tests/tmux_nix_migration_test.sh`
- Modify: `tests/wezterm_home_manager_migration_test.sh`
- Modify: `tests/yazi_home_manager_migration_test.sh`
- Modify: `tests/zsh_nix_migration_test.sh`

- [ ] **Step 1: Update each test path from `.config/nix/...` to `nix/...`**

Examples to apply consistently:

```sh
home_nix="$repo_root/nix/home-manager/home.nix"
flake_nix="$repo_root/nix/flake.nix"
config_nix="$repo_root/nix/nix-darwin/configuration.nix"
```

- [ ] **Step 2: Run the focused path tests to verify they fail before the tree move**

Run:
```bash
bash tests/home_manager_only_flake_test.sh
bash tests/mise_home_manager_bootstrap_test.sh
bash tests/wezterm_home_manager_migration_test.sh
```

Expected: FAIL because the repository still stores files under `.config/nix`

- [ ] **Step 3: Commit the failing test changes**

```bash
git add tests/bacon_home_manager_migration_test.sh tests/direnv_zsh_check_skip_test.sh tests/ghconfig_paths_test.sh tests/gitconfig_paths_test.sh tests/home_manager_only_flake_test.sh tests/mise_home_manager_bootstrap_test.sh tests/nix_darwin_reset_test.sh tests/tmux_nix_migration_test.sh tests/wezterm_home_manager_migration_test.sh tests/yazi_home_manager_migration_test.sh tests/zsh_nix_migration_test.sh
git commit -m "test: expect nix tree at repo root"
```

## Chunk 2: Move the Nix tree and keep evaluation intact

### Task 2: Relocate `.config/nix` to `nix/`

**Files:**
- Move: `.config/nix` -> `nix`
- Check: `nix/flake.nix`
- Check: `nix/home-manager/home.nix`
- Check: `nix/nix-darwin/configuration.nix`
- Test: path tests from Chunk 1

- [ ] **Step 1: Move the directory in one rename**

Run:
```bash
git mv .config/nix nix
```

Expected: `flake.nix`, `flake.lock`, `common/`, `home-manager/`, and `nix-darwin/` all move together

- [ ] **Step 2: Inspect the relocated tree**

Run:
```bash
find nix -maxdepth 3 -type f | sort
```

Expected: the same files now live under `nix/...`

- [ ] **Step 3: Re-run the focused path tests**

Run:
```bash
bash tests/home_manager_only_flake_test.sh
bash tests/mise_home_manager_bootstrap_test.sh
bash tests/wezterm_home_manager_migration_test.sh
```

Expected: PASS

- [ ] **Step 4: Re-run the full affected shell regression set**

Run:
```bash
bash tests/bacon_home_manager_migration_test.sh
bash tests/direnv_zsh_check_skip_test.sh
bash tests/ghconfig_paths_test.sh
bash tests/gitconfig_paths_test.sh
bash tests/home_manager_only_flake_test.sh
bash tests/mise_home_manager_bootstrap_test.sh
bash tests/nix_darwin_reset_test.sh
bash tests/tmux_nix_migration_test.sh
bash tests/wezterm_home_manager_migration_test.sh
bash tests/yazi_home_manager_migration_test.sh
bash tests/zsh_nix_migration_test.sh
```

Expected: PASS

- [ ] **Step 5: Commit the tree relocation**

```bash
git add nix
git commit -m "refactor(nix): move flake tree to repo root"
```

## Chunk 3: Update practical flake command references

### Task 3: Replace `.config/nix#...` with `./nix#...` in active command examples

**Files:**
- Modify: any non-historical repo files that still contain runtime command examples
- Check: `tests/*` if command strings appear there
- Check: current active docs or notes outside ignored historical docs

- [ ] **Step 1: Search for practical command references**

Run:
```bash
rg -n '\\.config/nix#|home-manager (build|switch) --flake \\.config/nix#|nix eval \\.config/nix#' . -g '!docs/superpowers/*' -g '!result' -g '!.git' -g '!.worktrees'
```

Expected: only actionable references remain in active files

- [ ] **Step 2: Update each remaining command to path-flake syntax**

Examples:

```text
home-manager build --flake ./nix#KokiAoyagi
home-manager switch --flake ./nix#KokiAoyagi
nix eval ./nix#homeConfigurations.KokiAoyagi.config.home.username --raw
```

- [ ] **Step 3: Re-run the search to confirm there are no active `.config/nix#...` references left**

Run:
```bash
rg -n '\\.config/nix#|home-manager (build|switch) --flake \\.config/nix#|nix eval \\.config/nix#' . -g '!docs/superpowers/*' -g '!result' -g '!.git' -g '!.worktrees'
```

Expected: no matches

- [ ] **Step 4: Commit the command-reference cleanup**

```bash
git add .
git commit -m "docs: update active flake commands to repo-root nix path"
```

## Chunk 4: Clean up legacy `~/.config/nix` symlinks

### Task 4: Teach `install.sh` to remove the old symlink when it points into this repo

**Files:**
- Modify: `install.sh`
- Create or modify test if needed: `tests/install_dotfiles_test.sh` or a new focused shell test

- [ ] **Step 1: Add targeted legacy cleanup for `~/.config/nix`**

Implementation shape:

```bash
cleanup_legacy_nix_link() {
    local target="$HOME/.config/nix"
    local current_target=""

    if [ ! -L "$target" ]; then
        return
    fi

    current_target="$(readlink "$target")"
    case "$current_target" in
        "$DOTFILES_DIR"/.config/nix)
            rm "$target"
            echo "✓ removed legacy nix link $target"
            ;;
    esac
}
```

- [ ] **Step 2: Call the cleanup during install**

Expected position: near `cleanup_legacy_ai_links`, before normal linking completes

- [ ] **Step 3: Add a focused test or extend an existing install test**

The test should prove:
- a repo-owned `~/.config/nix` symlink is removed
- unrelated files are untouched

- [ ] **Step 4: Run the install-related regression test**

Run the exact affected shell test after updating it

Expected: PASS

- [ ] **Step 5: Commit the cleanup**

```bash
git add install.sh tests/install_dotfiles_test.sh
git commit -m "fix(install): remove legacy nix config symlink"
```

## Chunk 5: Verify the relocated flake end-to-end

### Task 5: Prove the new root path evaluates and builds

**Files:**
- Check: `nix/flake.nix`
- Check: `nix/home-manager/home.nix`
- Check: `nix/nix-darwin/configuration.nix`

- [ ] **Step 1: Evaluate the Home Manager entry**

Run:
```bash
nix eval ./nix#homeConfigurations.KokiAoyagi.config.home.username --raw
```

Expected: `KokiAoyagi`

- [ ] **Step 2: Evaluate the darwin entry**

Run:
```bash
nix eval ./nix#darwinConfigurations.KokiAoyagi.system.primaryUser --raw
```

Expected: `KokiAoyagi`

- [ ] **Step 3: Build the Home Manager generation from the new path**

Run:
```bash
home-manager build --flake ./nix#KokiAoyagi
```

Expected: PASS and a new `result` generation

- [ ] **Step 4: Inspect the build output path**

Run:
```bash
ls -ld result && readlink result
```

Expected: `result` points at a `home-manager-generation` in `/nix/store`

- [ ] **Step 5: Commit any final verification-driven fixes**

```bash
git add .
git commit -m "fix(nix): align repo-root flake relocation"
```

## Unresolved questions

- None.
