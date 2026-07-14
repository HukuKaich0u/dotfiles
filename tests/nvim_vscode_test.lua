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
assert(mappings["n\0<Space>"].rhs == "<Nop>", "normal-mode Space should map to <Nop>")
assert(mappings["v\0<Space>"].rhs == "<Nop>", "visual-mode Space should map to <Nop>")

local function run_mapping(lhs)
  local mapping = assert(mappings["n\0" .. lhs], "missing normal-mode mapping: " .. lhs)
  assert(type(mapping.rhs) == "function", "mapping should call Cursor through a Lua function: " .. lhs)
  assert(mapping.opts.silent == true, "mapping should be silent: " .. lhs)
  assert(type(mapping.opts.desc) == "string" and mapping.opts.desc ~= "", "mapping should have a description: " .. lhs)
  actions = {}
  mapping.rhs()
  assert(#actions == 1, "mapping should invoke exactly one Cursor action: " .. lhs)
  return actions[1]
end

local expected_actions = {
  ["<leader>ee"] = "workbench.view.explorer",
  ["<leader>pf"] = "workbench.action.quickOpen",
  ["<leader>ps"] = "workbench.action.findInFiles",
  ["<leader>pws"] = "workbench.action.findInFiles",
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

local expected_normal_mapping_count = 1
for _ in pairs(expected_actions) do
  expected_normal_mapping_count = expected_normal_mapping_count + 1
end

local actual_normal_mapping_count = 0
for key in pairs(mappings) do
  if key:sub(1, 2) == "n\0" then
    actual_normal_mapping_count = actual_normal_mapping_count + 1
  end
end
assert(
  actual_normal_mapping_count == expected_normal_mapping_count,
  "Cursor config should define exactly the expected normal-mode mappings"
)

for lhs, command in pairs(expected_actions) do
  if lhs ~= "<leader>pws" then
    local action = run_mapping(lhs)
    assert(action.name == command, lhs .. " should invoke " .. command .. ", got " .. tostring(action.name))
  end
end

vim.api.nvim_buf_set_lines(0, 0, -1, false, { "search_target" })
vim.api.nvim_win_set_cursor(0, { 1, 1 })
local word_search = run_mapping("<leader>pws")
assert(word_search.name == "workbench.action.findInFiles", "<leader>pws should invoke find in files")
assert(word_search.opts and word_search.opts.args, "<leader>pws should pass Cursor command arguments")
assert(word_search.opts.args.query == "search_target", "<leader>pws should search the word under the cursor")

print("Cursor Neovim tests passed")
