local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo_root .. "/nix/modules/home/assets/nvim")
vim.o.termguicolors = true

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

vim.o.background = "light"
vim.cmd("colorscheme sethy-default")

assert_equal(vim.g.colors_name, "sethy-default", "sethy-default should set colors_name")
assert_equal(vim.o.background, "dark", "sethy-default should force a dark background")

for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat", "FloatBorder", "Pmenu", "SignColumn", "StatusLine" }) do
  assert_equal(hl(group).bg, nil, group .. " should have a transparent background")
end

-- 構文ハイライトは default のまま残す
assert_equal(hl("String").fg, tonumber("b3f6c0", 16), "String should keep the default colorscheme color")
assert_equal(hl("PmenuSel").reverse, nil, "PmenuSel should not use reverse video")

vim.o.background = "light"
vim.cmd("colorscheme sethy-vim")

assert_equal(vim.g.colors_name, "sethy-vim", "sethy-vim should set colors_name")
assert_equal(vim.o.background, "dark", "sethy-vim should force a dark background")

for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat", "FloatBorder", "Pmenu", "SignColumn", "StatusLine" }) do
  assert_equal(hl(group).bg, nil, group .. " should have a transparent background in sethy-vim")
end

-- vim の原色の面 (Pmenu の Magenta、ColorColumn の DarkRed、terminal statusline の LightGreen) を残さない
assert_equal(hl("ColorColumn").bg, hl("CursorLine").bg, "ColorColumn should use the same subtle background as CursorLine")
assert_equal(hl("StatusLineTerm").bg, nil, "StatusLineTerm should not use a bright green background")

-- 構文色は vim の色相を保ったまま原色を避ける
for _, group in ipairs({ "Comment", "Constant", "Identifier", "Statement", "PreProc", "Type", "Special" }) do
  local fg = hl(group).fg
  assert(fg, group .. " should have a foreground color")
  local r, g, b = math.floor(fg / 0x10000), math.floor(fg / 0x100) % 0x100, fg % 0x100
  local saturation = (math.max(r, g, b) - math.min(r, g, b)) / math.max(r, g, b)
  assert(saturation < 0.6, ("%s should be muted, got #%06x"):format(group, fg))
end

-- vim の link 構造は引き継ぎつつ、素の変数はシアンにしない
assert_equal(vim.api.nvim_get_hl(0, { name = "@function" }).link, "Function", "@function should keep vim's link")
assert_equal(hl("@variable").fg, hl("Normal").fg, "@variable should use the normal foreground")

-- sethy-vim の構文上書きが sethy-default に残らない
vim.cmd("colorscheme sethy-default")
assert_equal(hl("String").fg, tonumber("b3f6c0", 16), "String should return to the default color after switching from sethy-vim")
assert_equal(vim.api.nvim_get_hl(0, { name = "@variable" }).link, nil, "@variable should not keep sethy-vim's override")
