# Cursor Global Leader Fallback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `<Space>pf`, `<Space>ps`, `<Space>ee`, and `<Space>gg` available from empty editor groups and non-input Cursor surfaces without changing Neovim editor behavior.

**Architecture:** Keep the existing `nvim-vscode/init.lua` mappings as the editor-only path. Add four Cursor-native keybinding fallbacks whose shared `when` clause excludes text editors, inputs, terminals, and accessibility overlays, so exactly one layer handles a chord in each context.

**Tech Stack:** Cursor 3.11.19 keybindings JSONC, Cursor's bundled `jsonc-parser`, vscode-neovim 1.19.0, Neovim 0.12.3, shell verification

---

## File map

- Modify: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json` — append the four live native fallbacks without changing the existing 69 entries.
- Create: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.before-global-leader-2026-07-15.json.bak` — exact durable rollback copy of the pre-change file.
- Temporary: `/tmp/cursor-keybindings.global-leader.json` — validated candidate before replacing the live file.
- Verify only: `nix/modules/home/assets/nvim-vscode/init.lua` — retain the existing editor-side mappings unchanged.
- Verify only: `tests/nvim_vscode_test.lua` — retain the existing mapping regression coverage unchanged.

### Task 1: Capture the baseline and prove the fallback is missing

**Files:**
- Read: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json`
- Create: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.before-global-leader-2026-07-15.json.bak`
- Create: `/tmp/cursor-keybindings.global-leader.json`

- [ ] **Step 1: Verify the current live baseline**

Run:

```bash
node -e 'const fs=require("fs");const j=require("/Applications/Cursor.app/Contents/Resources/app/node_modules/jsonc-parser/lib/umd/main.js");const e=[];const a=j.parse(fs.readFileSync(process.argv[1],"utf8"),e);if(e.length)throw new Error(JSON.stringify(e));const q=a.filter(x=>x.key==="q"&&x.command==="workbench.action.focusActiveEditorGroup"&&x.when==="sideBarFocus && !inputFocus");const keys=new Set(["space p f","space p s","space e e","space g g"]);const fallbacks=a.filter(x=>keys.has(x.key));if(a.length!==69||q.length!==1||fallbacks.length!==0)process.exit(2);console.log("baseline: 69 entries, q binding present, global fallbacks absent")' '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json'
```

Expected: exit 0 and `baseline: 69 entries, q binding present, global fallbacks absent`.

- [ ] **Step 2: Create durable and working copies**

Run:

```bash
set -eu
live='/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json'
backup='/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.before-global-leader-2026-07-15.json.bak'
working='/tmp/cursor-keybindings.global-leader.json'

if test -e "$backup"; then
  if cmp "$live" "$backup"; then
    printf '%s\n' 'durable backup already exists and matches live; reusing it'
  else
    printf '%s\n' 'durable backup differs from live; refusing to overwrite it' >&2
    exit 1
  fi
else
  cp "$live" "$backup"
  printf '%s\n' 'durable backup created'
fi

cp "$live" "$working"
```

Expected when the durable backup is absent: exit 0, print `durable backup created`, then refresh the working copy from live.

Expected when the durable backup already exists and is byte-identical to live: `cmp` exits 0, print `durable backup already exists and matches live; reusing it`, leave the durable backup untouched, then refresh the working copy from live.

Expected when the durable backup already exists but differs from live: `cmp` exits nonzero, print `durable backup differs from live; refusing to overwrite it`, exit 1 without overwriting the durable backup, and do not refresh the working copy.

- [ ] **Step 3: Verify the copies are exact**

Run:

```bash
cmp '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json' '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.before-global-leader-2026-07-15.json.bak'
cmp '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json' /tmp/cursor-keybindings.global-leader.json
shasum -a 256 '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json' '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.before-global-leader-2026-07-15.json.bak' /tmp/cursor-keybindings.global-leader.json
```

Expected: both `cmp` commands exit 0 and all three SHA-256 values match.

- [ ] **Step 4: Run the target assertion and verify RED**

Run:

```bash
node -e 'const fs=require("fs");const j=require("/Applications/Cursor.app/Contents/Resources/app/node_modules/jsonc-parser/lib/umd/main.js");const e=[];const a=j.parse(fs.readFileSync(process.argv[1],"utf8"),e);if(e.length)throw new Error(JSON.stringify(e));const when="!editorTextFocus && !inputFocus && !terminalFocus && !accessibleViewIsShown && !accessibilityHelpIsShown";const expected={"space p f":"workbench.action.quickOpen","space p s":"workbench.action.findInFiles","space e e":"workbench.view.explorer","space g g":"workbench.view.scm"};for(const [key,command] of Object.entries(expected)){const hits=a.filter(x=>x.key===key&&x.command===command&&x.when===when);if(hits.length!==1){console.error(`missing ${key} -> ${command}`);process.exit(1)}}' /tmp/cursor-keybindings.global-leader.json
```

Expected: exit 1 with `missing space p f -> workbench.action.quickOpen`, proving the current file does not satisfy the feature.

### Task 2: Add the four native fallbacks to the candidate

**Files:**
- Modify: `/tmp/cursor-keybindings.global-leader.json`
- Compare: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.before-global-leader-2026-07-15.json.bak`

- [ ] **Step 1: Append exactly four objects**

Use `apply_patch` on `/tmp/cursor-keybindings.global-leader.json`. Replace the final object and closing bracket:

```jsonc
  {
    "key": "q",
    "command": "workbench.action.focusActiveEditorGroup",
    "when": "sideBarFocus && !inputFocus"
  }
]
```

with:

```jsonc
  {
    "key": "q",
    "command": "workbench.action.focusActiveEditorGroup",
    "when": "sideBarFocus && !inputFocus"
  },
  {
    "key": "space p f",
    "command": "workbench.action.quickOpen",
    "when": "!editorTextFocus && !inputFocus && !terminalFocus && !accessibleViewIsShown && !accessibilityHelpIsShown"
  },
  {
    "key": "space p s",
    "command": "workbench.action.findInFiles",
    "when": "!editorTextFocus && !inputFocus && !terminalFocus && !accessibleViewIsShown && !accessibilityHelpIsShown"
  },
  {
    "key": "space e e",
    "command": "workbench.view.explorer",
    "when": "!editorTextFocus && !inputFocus && !terminalFocus && !accessibleViewIsShown && !accessibilityHelpIsShown"
  },
  {
    "key": "space g g",
    "command": "workbench.view.scm",
    "when": "!editorTextFocus && !inputFocus && !terminalFocus && !accessibleViewIsShown && !accessibilityHelpIsShown"
  }
]
```

- [ ] **Step 2: Verify JSONC syntax and the exact semantic delta**

Run:

```bash
node -e 'const fs=require("fs");const j=require("/Applications/Cursor.app/Contents/Resources/app/node_modules/jsonc-parser/lib/umd/main.js");function parse(p){const e=[];const a=j.parse(fs.readFileSync(p,"utf8"),e);if(e.length)throw new Error(`${p}: ${JSON.stringify(e)}`);return a}const before=parse(process.argv[1]);const after=parse(process.argv[2]);const when="!editorTextFocus && !inputFocus && !terminalFocus && !accessibleViewIsShown && !accessibilityHelpIsShown";const expected=[{key:"space p f",command:"workbench.action.quickOpen",when},{key:"space p s",command:"workbench.action.findInFiles",when},{key:"space e e",command:"workbench.view.explorer",when},{key:"space g g",command:"workbench.view.scm",when}];if(before.length!==69||after.length!==73)process.exit(2);if(JSON.stringify(after.slice(0,before.length))!==JSON.stringify(before))process.exit(3);if(JSON.stringify(after.slice(before.length))!==JSON.stringify(expected))process.exit(4);for(const item of expected){if(after.filter(x=>x.key===item.key).length!==1)process.exit(5)}console.log("candidate: exact four-entry semantic delta")' '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.before-global-leader-2026-07-15.json.bak' /tmp/cursor-keybindings.global-leader.json
```

Expected: exit 0 and `candidate: exact four-entry semantic delta`.

- [ ] **Step 3: Re-run the target assertion and verify GREEN**

Run the Task 1 Step 4 command against `/tmp/cursor-keybindings.global-leader.json` again.

Expected: exit 0 with no `missing` message.

### Task 3: Replace the live file and verify deployment

**Files:**
- Modify: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json`
- Verify: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/settings.json`

- [ ] **Step 1: Record the settings hash before deployment**

Run:

```bash
shasum -a 256 '/Users/KokiAoyagi/Library/Application Support/Cursor/User/settings.json'
```

Expected: one SHA-256 value; retain it for Step 4.

- [ ] **Step 2: Prove baseline freshness, then replace the live keybindings**

Run:

```bash
set -eu
cmp '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json' '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.before-global-leader-2026-07-15.json.bak'
cp /tmp/cursor-keybindings.global-leader.json '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json'
```

Expected when live is still byte-identical to the durable baseline backup: `cmp` exits 0, the validated candidate replaces live, and the step exits 0.

Expected when live has changed since Task 1: `cmp` exits nonzero and `set -e` stops deployment before `cp`, leaving both live and the durable backup untouched.

- [ ] **Step 3: Verify live semantic state**

Run the Task 2 Step 2 semantic-delta command again, replacing its second argument with the live `keybindings.json` path.

Expected: exit 0 and `candidate: exact four-entry semantic delta`.

- [ ] **Step 4: Prove unrelated settings and dotfiles files were not changed**

Run:

```bash
shasum -a 256 '/Users/KokiAoyagi/Library/Application Support/Cursor/User/settings.json'
git status --short --untracked-files=all
git diff -- nix/modules/home/assets/nvim-vscode/init.lua tests/nvim_vscode_test.lua
```

Expected: the settings hash matches Step 1, `git status` is empty, and the targeted `git diff` is empty.

### Task 4: Run regression checks and Cursor smoke tests

**Files:**
- Verify: `tests/nvim_vscode_test.lua`
- Verify: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json`

- [ ] **Step 1: Run the focused Neovim regression test**

Run:

```bash
nvim --headless -l tests/nvim_vscode_test.lua
```

Expected: exit 0 and `Cursor Neovim tests passed`. Non-fatal headless log/server warnings on macOS may be ignored if the process exits 0.

- [ ] **Step 2: Run the full dotfiles suite**

Run:

```bash
./tests/run.sh
```

Expected on this macOS host: every test except `linux_apt_install_script_test.sh` passes. The sole accepted failure is `stat: cannot read file system information for '%Lp'`; any additional failure blocks completion.

- [ ] **Step 3: Reload Cursor and test empty/non-input surfaces**

Run `Developer: Reload Window`, close all editor tabs, then verify:

1. `Space p f` opens Quick Open.
2. `Space p s` opens Find in Files.
3. `Space e e` opens Explorer.
4. `Space g g` opens Source Control.
5. From a focused Explorer or Source Control list, the same four chords still work.

Expected: all four commands work without an open file and from non-input sidebars.

- [ ] **Step 4: Test excluded contexts and the existing editor path**

Verify:

1. Search, SCM commit, and Chat inputs accept ordinary spaces and letters.
2. The integrated Terminal accepts `space p f` as terminal input and does not open Quick Open.
3. In an editor with vscode-neovim Normal mode, all four chords still invoke their existing commands.
4. In editor Insert mode, ordinary spaces and letters remain text input.
5. `<Space>pws` still searches the word under the cursor only from the editor.
6. Sidebar `q` still returns focus to the editor while sidebar inputs still accept `q`.

Expected: fallback commands fire only in the contexts permitted by the shared `when` clause.

- [ ] **Step 5: Perform the final clean-state check**

Run:

```bash
git status --short --untracked-files=all
git log --oneline -3
```

Expected: clean worktree; the design and implementation-plan documentation remain in separate commits, and the live Cursor change has not introduced an untracked dotfiles mutation.
