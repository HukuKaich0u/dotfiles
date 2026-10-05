local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo_root .. "/nix/modules/home/assets/nvim")
vim.cmd("filetype on")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)))
  end
end

require("Sethy.core.options")

local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")

local function open(name)
  vim.cmd("edit " .. vim.fn.fnameescape(tmp .. "/" .. name))
  return vim.wo.colorcolumn
end

-- コードのファイルでは 80 桁の線を出す
assert_equal(open("main.lua"), "80", "colorcolumn should be shown for code files")
assert_equal(open("app.ts"), "80", "colorcolumn should be shown for TypeScript files")

-- 文章のファイルでは出さない
assert_equal(open("README.md"), "", "colorcolumn should be hidden for markdown")
assert_equal(open("notes.txt"), "", "colorcolumn should be hidden for plain text")

-- 文章から同じ window でコードに戻ったら、また出す
assert_equal(open("main.lua"), "80", "colorcolumn should come back when returning to code in the same window")

-- plugin の画面のような buftype が付いた buffer では出さない
local scratch = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(scratch)
vim.bo[scratch].filetype = "lua"
assert_equal(vim.wo.colorcolumn, "", "colorcolumn should be hidden for scratch / plugin buffers")

-- 新しい window は既定で出さない
vim.cmd("vnew")
assert_equal(vim.wo.colorcolumn, "", "colorcolumn should be hidden for a new empty window")

vim.fn.delete(tmp, "rf")
