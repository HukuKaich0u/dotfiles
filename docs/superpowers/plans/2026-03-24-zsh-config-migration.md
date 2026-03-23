# Zsh Config Migration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `zsh` configuration management into `.config/zsh`, keep root `.zshrc` and `.zprofile` as thin wrappers, and preserve current shell behavior while enabling Homebrew-managed plugins and `starship`.

**Architecture:** The implementation adds a repository-managed `.config/zsh` tree with focused responsibility per file, then replaces root shell dotfiles with wrapper entrypoints and updates the installer to link both root wrappers. Existing shell behavior is migrated with minimal changes, redundant blocks are removed, and plugin loading becomes dynamic and soft-failing.

**Tech Stack:** `zsh`, POSIX shell/Bash installer, Homebrew-managed `zsh` plugins, `starship`

---

## Chunk 1: Repository Zsh Structure

### Task 1: Create the interactive entrypoint and split files

**Files:**
- Create: `.config/zsh/.zshrc`
- Create: `.config/zsh/env.zsh`
- Create: `.config/zsh/aliases.zsh`
- Create: `.config/zsh/completion.zsh`
- Create: `.config/zsh/plugins.zsh`
- Test: `zsh` syntax check against each new file

- [ ] **Step 1: Write the failing structure check**

Create a shell verification command that asserts the new files do not exist yet:

```bash
test -f .config/zsh/.zshrc
```

Expected: command exits non-zero before files are added.

- [ ] **Step 2: Run the failing structure check**

Run:

```bash
test -f .config/zsh/.zshrc
```

Expected: failure because `.config/zsh/.zshrc` does not exist yet.

- [ ] **Step 3: Write minimal entrypoint implementation**

Add `.config/zsh/.zshrc` with a short, deterministic load sequence:

```zsh
typeset -r ZSH_CONFIG_DIR="${0:A:h}"

source "$ZSH_CONFIG_DIR/env.zsh"
source "$ZSH_CONFIG_DIR/aliases.zsh"
source "$ZSH_CONFIG_DIR/completion.zsh"
source "$ZSH_CONFIG_DIR/plugins.zsh"
```

Keep the file focused on sourcing only.

- [ ] **Step 4: Implement the split files**

Populate:

- `env.zsh` with migrated exports and PATH updates from the current root `.zshrc`
- `aliases.zsh` with all aliases from the current root `.zshrc`
- `completion.zsh` with `autoload -Uz compinit` and `compinit`
- `plugins.zsh` with interactive behavior such as `bindkey`, `starship`, `zsh-autosuggestions`, and `zsh-syntax-highlighting`

Rules:
- remove the duplicated `PNPM_HOME` block while preserving PATH behavior
- keep `zsh-syntax-highlighting` last
- treat missing binaries or plugin scripts as non-fatal

- [ ] **Step 5: Run syntax verification for the new files**

Run:

```bash
zsh -n .config/zsh/.zshrc
zsh -n .config/zsh/env.zsh
zsh -n .config/zsh/aliases.zsh
zsh -n .config/zsh/completion.zsh
zsh -n .config/zsh/plugins.zsh
```

Expected: all commands succeed with exit code 0.

- [ ] **Step 6: Commit the repository zsh structure**

Run:

```bash
git add .config/zsh
git commit -m "feat(zsh): split zsh config into .config"
```

Expected: commit succeeds with only the new `.config/zsh` files staged.

### Task 2: Add repository-managed `starship` config

**Files:**
- Create: `.config/starship.toml`
- Test: shell/plugin smoke check after implementation

- [ ] **Step 1: Write the failing file check**

Run:

```bash
test -f .config/starship.toml
```

Expected: failure before the file exists.

- [ ] **Step 2: Create the minimal `starship` config**

Add `.config/starship.toml` with a valid minimal configuration. Start with a small file that preserves default behavior and can be customized later, for example a newline preference or prompt format only if required.

- [ ] **Step 3: Verify shell startup still succeeds with `starship` enabled**

Run:

```bash
STARSHIP_CONFIG="$PWD/.config/starship.toml" zsh -ic exit
```

Expected: shell exits successfully without startup errors.

- [ ] **Step 4: Commit the `starship` config**

Run:

```bash
git add .config/starship.toml
git commit -m "feat(zsh): add repository starship config"
```

Expected: commit succeeds with only the new `starship` file staged.

## Chunk 2: Wrappers And Installer

### Task 3: Replace root shell dotfiles with thin wrappers

**Files:**
- Modify: `.zshrc`
- Create: `.zprofile`
- Test: `zsh -n .zshrc`, `zsh -n .zprofile`

- [ ] **Step 1: Write the failing wrapper expectation**

Inspect the current root `.zshrc` and verify it still contains full configuration logic rather than wrapper logic:

```bash
rg "alias gotest|conda initialize|PNPM_HOME" .zshrc
```

Expected: at least one match, proving the wrapper conversion has not happened yet.

- [ ] **Step 2: Replace root `.zshrc` with a thin wrapper**

Implement a short wrapper that resolves the repository root from the wrapper file location and sources `.config/zsh/.zshrc` if present.

Example target shape:

```zsh
typeset -r DOTFILES_DIR="${0:A:h}"
typeset -r TARGET="$DOTFILES_DIR/.config/zsh/.zshrc"
[[ -f "$TARGET" ]] && source "$TARGET"
```

- [ ] **Step 3: Create root `.zprofile` as a thin wrapper**

Add the matching wrapper for `.config/zsh/.zprofile` using the same pattern and an existence guard.

- [ ] **Step 4: Verify wrapper syntax**

Run:

```bash
zsh -n .zshrc
zsh -n .zprofile
```

Expected: both commands succeed with exit code 0.

- [ ] **Step 5: Run an interactive shell smoke test**

Run:

```bash
ZDOTDIR="$HOME" HOME="$HOME" zsh -lic exit
```

Expected: command exits successfully, indicating login + interactive startup works with the new wrapper flow.

- [ ] **Step 6: Commit wrapper conversion**

Run:

```bash
git add .zshrc .zprofile
git commit -m "feat(zsh): use thin root zsh wrappers"
```

Expected: commit succeeds with only wrapper file changes staged.

### Task 4: Update the installer for `.zprofile`

**Files:**
- Modify: `install.sh`
- Test: installer output and linked-file verification

- [ ] **Step 1: Write the failing installer expectation**

Inspect the installer and confirm that only `.zshrc` is currently listed:

```bash
rg '^HOME_DOTFILES=' install.sh
```

Expected: output shows `.zshrc` only.

- [ ] **Step 2: Update installer dotfile list**

Change `HOME_DOTFILES` so the installer links both `.zshrc` and `.zprofile`.

Target shape:

```bash
HOME_DOTFILES=".zshrc .zprofile"
```

- [ ] **Step 3: Verify installer syntax**

Run:

```bash
bash -n install.sh
```

Expected: command succeeds with exit code 0.

- [ ] **Step 4: Run installer smoke test**

Run:

```bash
./install.sh
```

Expected: output includes successful handling for `.zshrc` and `.zprofile`, plus `.config/zsh` through the existing config-directory loop.

- [ ] **Step 5: Confirm linked files**

Run:

```bash
test -L "$HOME/.zshrc"
test -L "$HOME/.zprofile"
test -L "$HOME/.config/zsh"
```

Expected: all commands succeed after installer execution.

- [ ] **Step 6: Commit installer update**

Run:

```bash
git add install.sh
git commit -m "feat(installer): link zprofile with zsh config"
```

Expected: commit succeeds with only the installer change staged.

## Chunk 3: Final Verification

### Task 5: Verify migrated behavior end to end

**Files:**
- Verify: `.config/zsh/.zshrc`
- Verify: `.config/zsh/env.zsh`
- Verify: `.config/zsh/plugins.zsh`
- Verify: `.zshrc`
- Verify: `.zprofile`
- Verify: `install.sh`

- [ ] **Step 1: Run targeted syntax checks again**

Run:

```bash
zsh -n .config/zsh/.zshrc
zsh -n .config/zsh/.zprofile
zsh -n .config/zsh/env.zsh
zsh -n .config/zsh/aliases.zsh
zsh -n .config/zsh/completion.zsh
zsh -n .config/zsh/plugins.zsh
zsh -n .zshrc
zsh -n .zprofile
bash -n install.sh
```

Expected: all commands succeed.

- [ ] **Step 2: Run interactive plugin smoke test**

Run:

```bash
zsh -ic 'whence -w compinit; exit'
```

Expected: command succeeds and reports `compinit` is available.

- [ ] **Step 3: Run prompt/plugin smoke test**

Run:

```bash
zsh -ic 'typeset -p ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE >/dev/null 2>&1; exit 0'
```

Expected: shell starts without errors even if plugin-specific variables are unset.

- [ ] **Step 4: Review git diff for scope**

Run:

```bash
git diff --stat HEAD~4..HEAD
```

Expected: diff is limited to zsh config files, wrapper files, installer changes, and `starship` config.

- [ ] **Step 5: Create the final implementation commit if work was done without per-task commits**

Run:

```bash
git add .config/zsh .config/starship.toml .zshrc .zprofile install.sh
git commit -m "feat(zsh): migrate shell config into .config"
```

Expected: only needed if the earlier task-level commits were intentionally skipped.
