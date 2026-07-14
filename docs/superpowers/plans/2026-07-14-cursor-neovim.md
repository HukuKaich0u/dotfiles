# Cursor Neovim Isolation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Run vscode-neovim inside Cursor with a minimal `nvim-vscode` configuration that is fully isolated from the existing terminal Neovim configuration.

**Architecture:** Home Manager exposes a second Neovim config at `~/.config/nvim-vscode`, while Cursor launches the existing Neovim binary with `NVIM_APPNAME=nvim-vscode`. The Cursor-only `init.lua` contains no plugin manager or terminal-Neovim imports; it only maps normal-mode keys to Cursor commands through `require("vscode").action`. Cursor's local JSONC files remain machine-local and are edited only where they conflict with vscode-neovim.

**Tech Stack:** Neovim Lua, vscode-neovim Lua API, Nix/Home Manager, nix-darwin, Cursor JSONC settings, shell regression runner

---

## File map

- Create `nix/modules/home/assets/nvim-vscode/init.lua`: Cursor-only leader and Cursor command mappings.
- Create `tests/nvim_vscode_test.lua`: headless test with a fake `vscode` module; verifies isolation, Home Manager wiring, key modes, command names, and search arguments.
- Modify `nix/modules/home/programs/nvim.nix`: expose the Cursor-only config as `~/.config/nvim-vscode` without changing `~/.config/nvim`.
- Modify `/Users/KokiAoyagi/Library/Application Support/Cursor/User/settings.json`: machine-local vscode-neovim executable and `NVIM_APPNAME` settings only.
- Modify `/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json`: remove stale vscode-neovim default-key removals and scope the existing `Ctrl+d` Cursor binding away from Neovim normal mode.

The existing `nix/modules/home/assets/nvim/**` tree must not change.

### Task 1: Add the isolated Home Manager asset and tested Cursor mappings

**Files:**
- Create: `tests/nvim_vscode_test.lua`
- Create: `nix/modules/home/assets/nvim-vscode/init.lua`
- Modify: `nix/modules/home/programs/nvim.nix`

- [ ] **Step 1: Write the failing regression test**

Create `tests/nvim_vscode_test.lua` with this content:

```lua
local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")

local function read(path)
  local file = assert(io.open(repo_root .. "/" .. path, "r"))
  local content = file:read("*a")
  file:close()
  return content
end

local function assert_match(content, pattern, message)
  if not content:match(pattern) then
    error(message .. "\nmissing pattern: " .. pattern)
  end
end

local function assert_no_match(content, pattern, message)
  if content:match(pattern) then
    error(message .. "\nunexpected pattern: " .. pattern)
  end
end

local nvim_module = read("nix/modules/home/programs/nvim.nix")
assert_match(
  nvim_module,
  'xdg%.configFile%."nvim%-vscode"%.source = %.%./assets/nvim%-vscode;',
  "Home Manager should expose an isolated nvim-vscode config"
)

local regular_init = read("nix/modules/home/assets/nvim/init.lua")
assert_no_match(regular_init, 'require%("vscode"%)', "regular Neovim must not import the vscode API")
assert_no_match(regular_init, "vim%.g%.vscode", "regular Neovim must not branch for Cursor")

local actions = {}
local mappings = {}

package.loaded.vscode = nil
package.preload.vscode = function()
  return {
    action = function(name, opts)
      table.insert(actions, { name = name, opts = opts })
    end,
  }
end

local original_keymap_set = vim.keymap.set
vim.keymap.set = function(mode, lhs, rhs, opts)
  local modes = type(mode) == "table" and mode or { mode }
  for _, item in ipairs(modes) do
    mappings[item .. "\0" .. lhs] = { rhs = rhs, opts = opts or {} }
  end
end

local ok, err = pcall(dofile, repo_root .. "/nix/modules/home/assets/nvim-vscode/init.lua")
vim.keymap.set = original_keymap_set
package.preload.vscode = nil

if not ok then
  error(err)
end

assert(vim.g.mapleader == " ", "Cursor Neovim leader should be Space")
assert(vim.g.maplocalleader == " ", "Cursor Neovim local leader should be Space")
assert(mappings["n\0<Space>"], "Space should be disabled as a standalone normal-mode key")
assert(mappings["v\0<Space>"], "Space should be disabled as a standalone visual-mode key")

local function run_mapping(lhs)
  local mapping = assert(mappings["n\0" .. lhs], "missing normal-mode mapping: " .. lhs)
  assert(type(mapping.rhs) == "function", "mapping should call Cursor through a Lua function: " .. lhs)
  actions = {}
  mapping.rhs()
  assert(#actions == 1, "mapping should invoke exactly one Cursor action: " .. lhs)
  return actions[1]
end

local expected_actions = {
  ["<leader>ee"] = "workbench.view.explorer",
  ["<leader>pf"] = "workbench.action.quickOpen",
  ["<leader>ps"] = "workbench.action.findInFiles",
  ["gd"] = "editor.action.revealDefinition",
  ["gR"] = "editor.action.goToReferences",
  ["gi"] = "editor.action.goToImplementation",
  ["gt"] = "editor.action.goToTypeDefinition",
  ["K"] = "editor.action.showHover",
  ["<leader>rn"] = "editor.action.rename",
  ["<leader>vca"] = "editor.action.quickFix",
  ["<leader>d"] = "editor.action.showHover",
  ["<C-h>"] = "workbench.action.navigateLeft",
  ["<C-j>"] = "workbench.action.navigateDown",
  ["<C-k>"] = "workbench.action.navigateUp",
  ["<C-l>"] = "workbench.action.navigateRight",
}

for lhs, command in pairs(expected_actions) do
  local action = run_mapping(lhs)
  assert(action.name == command, lhs .. " should invoke " .. command .. ", got " .. tostring(action.name))
end

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "search_target" })
vim.api.nvim_win_set_cursor(0, { 1, 1 })
local word_search = run_mapping("<leader>pws")
assert(word_search.name == "workbench.action.findInFiles", "<leader>pws should invoke find in files")
assert(word_search.opts and word_search.opts.args, "<leader>pws should pass Cursor command arguments")
assert(word_search.opts.args.query == "search_target", "<leader>pws should search the word under the cursor")

print("Cursor Neovim tests passed")
```

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
nvim --headless -l tests/nvim_vscode_test.lua
```

Expected: FAIL because `nvim.nix` does not yet declare `nvim-vscode` and `nix/modules/home/assets/nvim-vscode/init.lua` does not exist.

- [ ] **Step 3: Add the Home Manager link**

Change `nix/modules/home/programs/nvim.nix` to:

```nix
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withPython3 = true;
    withRuby = true;
  };

  xdg.configFile."nvim".source = ../assets/nvim;
  xdg.configFile."nvim-vscode".source = ../assets/nvim-vscode;
}
```

- [ ] **Step 4: Implement the minimal Cursor-only init**

Create `nix/modules/home/assets/nvim-vscode/init.lua` with:

```lua
local vscode = require("vscode")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

local function action(command, opts)
  return function()
    vscode.action(command, opts)
  end
end

local function map(lhs, command, description)
  vim.keymap.set("n", lhs, action(command), {
    desc = description,
    silent = true,
  })
end

map("<leader>ee", "workbench.view.explorer", "Open Cursor Explorer")
map("<leader>pf", "workbench.action.quickOpen", "Find files in Cursor")
map("<leader>ps", "workbench.action.findInFiles", "Search text in Cursor")

vim.keymap.set("n", "<leader>pws", function()
  vscode.action("workbench.action.findInFiles", {
    args = { query = vim.fn.expand("<cword>") },
  })
end, { desc = "Search word under cursor", silent = true })

map("gd", "editor.action.revealDefinition", "Go to definition")
map("gR", "editor.action.goToReferences", "Find references")
map("gi", "editor.action.goToImplementation", "Go to implementation")
map("gt", "editor.action.goToTypeDefinition", "Go to type definition")
map("K", "editor.action.showHover", "Show hover information")
map("<leader>rn", "editor.action.rename", "Rename symbol")
map("<leader>vca", "editor.action.quickFix", "Show code actions")
map("<leader>d", "editor.action.showHover", "Show diagnostics")

map("<C-h>", "workbench.action.navigateLeft", "Focus left editor group")
map("<C-j>", "workbench.action.navigateDown", "Focus lower editor group")
map("<C-k>", "workbench.action.navigateUp", "Focus upper editor group")
map("<C-l>", "workbench.action.navigateRight", "Focus right editor group")
```

- [ ] **Step 5: Run focused and full tests and verify GREEN**

Run:

```bash
nvim --headless -l tests/nvim_vscode_test.lua
./tests/run.sh
```

Expected: focused test prints `Cursor Neovim tests passed`; the full runner ends with `all tests passed`.

- [ ] **Step 6: Confirm the regular Neovim tree did not change**

Run:

```bash
git diff --name-only d36f4f4 -- nix/modules/home/assets/nvim
```

Expected: no output.

- [ ] **Step 7: Commit the repository implementation**

```bash
git add tests/nvim_vscode_test.lua nix/modules/home/programs/nvim.nix nix/modules/home/assets/nvim-vscode/init.lua
git commit -m "feat(nvim): add isolated Cursor configuration"
```

### Task 2: Evaluate and activate the Home Manager configuration

**Files:**
- Verify: `nix/flake.nix`
- Apply: `nix/modules/home/programs/nvim.nix`
- Apply: `nix/modules/home/assets/nvim-vscode/init.lua`

- [ ] **Step 1: Evaluate the macOS configuration without switching**

Run:

```bash
nix eval ./nix#darwinConfigurations.KokiAoyagi.system.drvPath --raw
```

Expected: a `/nix/store/...-darwin-system-...drv` path and exit status 0.

- [ ] **Step 2: Build without changing the active system**

Run:

```bash
nix build ./nix#darwinConfigurations.KokiAoyagi.system --no-link
```

Expected: exit status 0 and no `result` symlink.

- [ ] **Step 3: Apply through the repository's macOS entrypoint**

Run:

```bash
./scripts/mac/apply-nix-darwin.sh
```

Expected: `darwin-rebuild switch` succeeds. This step requires sudo and must be run with explicit user approval if the execution environment requests it.

- [ ] **Step 4: Verify both Neovim configs exist independently**

Run:

```bash
readlink ~/.config/nvim
readlink ~/.config/nvim-vscode
test -f ~/.config/nvim/init.lua
test -f ~/.config/nvim-vscode/init.lua
```

Expected: both links resolve to different Nix store paths and all file checks exit 0.

### Task 3: Install vscode-neovim and configure Cursor's local settings

**Files:**
- Modify: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/settings.json`

- [ ] **Step 1: Install the extension**

Run:

```bash
cursor --install-extension asvetliakov.vscode-neovim
```

Expected: Cursor reports that `asvetliakov.vscode-neovim` was installed or is already installed.

- [ ] **Step 2: Back up the local settings outside the repository**

Run:

```bash
cp '/Users/KokiAoyagi/Library/Application Support/Cursor/User/settings.json' /tmp/cursor-settings.before-vscode-neovim.json
cp /tmp/cursor-settings.before-vscode-neovim.json /tmp/cursor-settings.vscode-neovim.json
```

Expected: an untouched backup and a separate working copy both exist in `/tmp`.

- [ ] **Step 3: Add only the two vscode-neovim settings**

Use `apply_patch` on `/tmp/cursor-settings.vscode-neovim.json`, changing the final property block from:

```jsonc
  "workbench.activityBar.orientation": "vertical"
}
```

to:

```jsonc
  "workbench.activityBar.orientation": "vertical",
  "vscode-neovim.NVIM_APPNAME": "nvim-vscode",
  "vscode-neovim.neovimExecutablePaths.darwin": "/etc/profiles/per-user/KokiAoyagi/bin/nvim"
}
```

- [ ] **Step 4: Validate the patched JSONC before replacing the live file**

Run:

```bash
node -e 'const fs=require("fs");const j=require("/Applications/Cursor.app/Contents/Resources/app/node_modules/jsonc-parser/lib/umd/main.js");const e=[];const v=j.parse(fs.readFileSync(process.argv[1],"utf8"),e);if(e.length)process.exit(1);if(v["vscode-neovim.NVIM_APPNAME"]!=="nvim-vscode")process.exit(2);if(v["vscode-neovim.neovimExecutablePaths.darwin"]!=="/etc/profiles/per-user/KokiAoyagi/bin/nvim")process.exit(3)' /tmp/cursor-settings.vscode-neovim.json
```

Expected: exit status 0.

- [ ] **Step 5: Replace the live settings with the validated copy**

Run:

```bash
cp /tmp/cursor-settings.vscode-neovim.json '/Users/KokiAoyagi/Library/Application Support/Cursor/User/settings.json'
```

Expected: copy succeeds. Writing outside the active repository requires explicit filesystem approval.

- [ ] **Step 6: Verify the extension and executable**

Run:

```bash
/etc/profiles/per-user/KokiAoyagi/bin/nvim --version | sed -n '1p'
find ~/.cursor/extensions -maxdepth 1 -type d -name 'asvetliakov.vscode-neovim-*' -print
```

Expected: Neovim reports version 0.10 or newer, and one vscode-neovim extension directory is printed.

### Task 4: Restore vscode-neovim defaults and make Neovim win in normal mode

**Files:**
- Modify: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json`

- [ ] **Step 1: Back up the local keybindings outside the repository**

Run:

```bash
cp '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json' /tmp/cursor-keybindings.before-vscode-neovim.json
cp /tmp/cursor-keybindings.before-vscode-neovim.json /tmp/cursor-keybindings.vscode-neovim.json
```

Expected: an untouched backup and a separate working copy both exist in `/tmp`.

- [ ] **Step 2: Remove exactly the stale vscode-neovim default-removal objects**

Use `apply_patch` on `/tmp/cursor-keybindings.vscode-neovim.json`. Delete every complete JSON object whose `command` starts with `-vscode-neovim.`. In the current file this means exactly these 14 key/command pairs:

```text
ctrl+d               -vscode-neovim.send
ctrl+d               -vscode-neovim.ctrl-d
ctrl+f               -vscode-neovim.ctrl-f
ctrl+f               -vscode-neovim.send
ctrl+m               -vscode-neovim.send             (insert)
ctrl+m               -vscode-neovim.send             (normal)
ctrl+m               -vscode-neovim.send-cmdline
ctrl+[               -vscode-neovim.escape
escape               -vscode-neovim.escape           (normal)
escape               -vscode-neovim.escape           (non-normal)
ctrl+k               -vscode-neovim.send             (normal)
ctrl+k               -vscode-neovim.send             (insert)
ctrl+[BracketLeft]   -vscode-neovim.escape
ctrl+[               -vscode-neovim.send
```

Keep the positive `vscode-neovim.escape` and `vscode-neovim.send` objects. Do not change terminal, Composer, Notebook, Explorer, or search-result bindings.

- [ ] **Step 3: Scope the existing Ctrl+d Cursor command away from normal mode**

In the same `/tmp/cursor-keybindings.vscode-neovim.json` file, change only this object:

```jsonc
  {
    "key": "ctrl+d",
    "command": "editor.action.addSelectionToNextFindMatch",
    "when": "editorFocus"
  },
```

to:

```jsonc
  {
    "key": "ctrl+d",
    "command": "editor.action.addSelectionToNextFindMatch",
    "when": "editorFocus && (!neovim.init || neovim.mode == 'insert')"
  },
```

- [ ] **Step 4: Validate the JSONC and conflict invariants**

Run:

```bash
node -e 'const fs=require("fs");const j=require("/Applications/Cursor.app/Contents/Resources/app/node_modules/jsonc-parser/lib/umd/main.js");const e=[];const a=j.parse(fs.readFileSync(process.argv[1],"utf8"),e);if(e.length)process.exit(1);if(a.some(x=>String(x.command||"").startsWith("-vscode-neovim.")))process.exit(2);const d=a.find(x=>x.key==="ctrl+d"&&x.command==="editor.action.addSelectionToNextFindMatch");if(!d||d.when!=="editorFocus && (!neovim.init || neovim.mode == 'insert')")process.exit(3)' /tmp/cursor-keybindings.vscode-neovim.json
```

Expected: exit status 0.

- [ ] **Step 5: Replace the live keybindings with the validated copy**

Run:

```bash
cp /tmp/cursor-keybindings.vscode-neovim.json '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json'
```

Expected: copy succeeds. Writing outside the active repository requires explicit filesystem approval.

### Task 5: Verify the integrated setup and perform the Cursor smoke test

**Files:**
- Verify: `tests/nvim_vscode_test.lua`
- Verify: `nix/modules/home/assets/nvim-vscode/init.lua`
- Verify: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/settings.json`
- Verify: `/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json`

- [ ] **Step 1: Re-run repository verification from a clean checkout state**

Run:

```bash
git status --short
nvim --headless -l tests/nvim_vscode_test.lua
./tests/run.sh
nix eval ./nix#darwinConfigurations.KokiAoyagi.system.drvPath --raw
```

Expected: worktree has no uncommitted implementation changes, Cursor test passes, full test suite passes, and Nix evaluation prints a store derivation path.

- [ ] **Step 2: Verify regular Neovim still starts with its original app name**

Run:

```bash
nvim --headless '+lua assert(vim.env.NVIM_APPNAME == nil or vim.env.NVIM_APPNAME == "")' +qa
```

Expected: exit status 0. This confirms a terminal launch does not inherit Cursor's app name.

- [ ] **Step 3: Reload Cursor**

In Cursor, run `Developer: Reload Window` from the Command Palette.

Expected: vscode-neovim initializes without an error notification. If it does not, open `Output: Focus on Output View`, select `vscode-neovim logs`, correct only the reported Cursor-specific issue, then run `Neovim: Restart Extension`.

- [ ] **Step 4: Check modal editing**

Open a tracked source file and verify:

```text
i        enters Insert mode
Esc      returns to Normal mode
v        enters Visual mode
y/d/p    perform Neovim operators in the editor
```

Expected: all modes and operators behave through vscode-neovim.

- [ ] **Step 5: Check file, search, and code mappings**

Verify each mapping in normal mode:

```text
Space ee   Explorer
Space pf   Quick Open
Space ps   Find in Files
Space pws  Find in Files with the cursor word prefilled
gd         Definition
gR         References
gi         Implementation
gt         Type Definition
K          Hover
Space rn   Rename
Space vca  Code Action
Space d    Diagnostic/Hover details
```

Expected: each action opens Cursor's native UI and no terminal-Neovim plugin UI appears.

- [ ] **Step 6: Check editor-group navigation and non-editor contexts**

Create at least two editor groups and verify `Ctrl+h/j/k/l` moves between them. Then focus the integrated terminal, Composer input, and a Notebook input if available.

Expected: Editor Group navigation works in Neovim normal mode; terminal and Cursor input contexts retain their existing shortcuts.

- [ ] **Step 7: Confirm final repository and external configuration state**

Run:

```bash
git status --short --branch
git log -2 --oneline
node -e 'const fs=require("fs");const j=require("/Applications/Cursor.app/Contents/Resources/app/node_modules/jsonc-parser/lib/umd/main.js");for(const f of process.argv.slice(1)){const e=[];j.parse(fs.readFileSync(f,"utf8"),e);if(e.length){console.error(f,e);process.exit(1)}}' '/Users/KokiAoyagi/Library/Application Support/Cursor/User/settings.json' '/Users/KokiAoyagi/Library/Application Support/Cursor/User/keybindings.json'
```

Expected: dotfiles is clean, the implementation commit follows the design/plan commits, and both Cursor JSONC files parse successfully.
