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

local syntax_groups = { "Comment", "Constant", "Identifier", "Statement", "PreProc", "Type" }

local function rgb(color)
  return math.floor(color / 0x10000), math.floor(color / 0x100) % 0x100, color % 0x100
end

local function hue(color)
  local r, g, b = rgb(color)
  local max, min = math.max(r, g, b), math.min(r, g, b)
  if max == min then
    return 0
  end
  local d = max - min
  local h
  if max == r then
    h = ((g - b) / d) % 6
  elseif max == g then
    h = (b - r) / d + 2
  else
    h = (r - g) / d + 4
  end
  return h * 60
end

vim.cmd("colorscheme vim")
local vim_fg = {}
for _, group in ipairs(syntax_groups) do
  vim_fg[group] = hl(group).fg
end

vim.o.background = "light"
vim.cmd("colorscheme sethy-vim")

assert_equal(vim.g.colors_name, "sethy-vim", "sethy-vim should set colors_name")
assert_equal(vim.o.background, "dark", "sethy-vim should force a dark background")

for _, group in ipairs({ "Normal", "NormalNC", "NormalFloat", "FloatBorder", "Pmenu", "SignColumn", "StatusLine" }) do
  assert_equal(hl(group).bg, nil, group .. " should have a transparent background in sethy-vim")
end

-- vim の明るい色の面 (Pmenu の Magenta、terminal statusline の LightGreen) は残さない
assert_equal(hl("StatusLineTerm").bg, nil, "StatusLineTerm should not use a bright green background")

-- 構文色は vim の色相を保つ
for _, group in ipairs(syntax_groups) do
  local fg = hl(group).fg
  assert(fg, group .. " should have a foreground color")
  local diff = math.abs(hue(fg) - hue(vim_fg[group]))
  diff = math.min(diff, 360 - diff)
  assert(diff <= 10, ("%s should keep vim's hue: #%06x vs #%06x"):format(group, fg, vim_fg[group]))
end

-- ネオンに近い色だけは vim より抑える
for _, group in ipairs({ "Identifier", "Statement", "Type" }) do
  local r, g, b = rgb(hl(group).fg)
  local vr, vg, vb = rgb(vim_fg[group])
  assert(r + g + b < vr + vg + vb, group .. " should be dimmer than vim's original")
end

assert_equal(vim.api.nvim_get_hl(0, { name = "@function" }).link, "Function", "@function should keep vim's link")

-- vim の link 構造 (変数もシアン) は引き継ぐ
assert_equal(vim.api.nvim_get_hl(0, { name = "@variable" }).link, "Identifier", "@variable should keep vim's link")

-- sethy-vim の上書きが sethy-default に残らない
vim.cmd("colorscheme sethy-default")
assert_equal(hl("String").fg, tonumber("b3f6c0", 16), "String should return to the default color after switching from sethy-vim")
assert_equal(hl("@variable").fg, hl("Normal").fg, "@variable should not keep sethy-vim's override after switching")
