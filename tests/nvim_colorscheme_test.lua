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

-- 80 桁の線は vim の DarkRed ではなく、色味のない灰色にする
do
  local r, g, b = rgb(hl("ColorColumn").bg)
  assert(r == g and g == b, ("ColorColumn should be grey, got #%06x"):format(hl("ColorColumn").bg))
  assert(hl("ColorColumn").bg ~= hl("CursorLine").bg, "ColorColumn should be distinguishable from CursorLine")
end

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

-- 実際のコードで、変数・引数・フィールド・関数呼び出しが別の色になる
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "local function greet(name)",
  "  local user = { name = name }",
  "  return user.name:upper()",
  "end",
})
vim.treesitter.start(buf, "lua")
vim.treesitter.get_parser(buf, "lua"):parse()

local function fg_at(row, col)
  local captures = vim.treesitter.get_captures_at_pos(buf, row, col)
  local group = "Normal"
  for _, capture in ipairs(captures) do
    if capture.lang == "lua" then
      group = "@" .. capture.capture
    end
  end
  return hl(group).fg, group
end

local roles = {
  variable = { fg_at(2, 9) }, -- user
  parameter = { fg_at(0, 21) }, -- name (引数)
  member = { fg_at(2, 14) }, -- .name
  method = { fg_at(2, 19) }, -- :upper()
  function_name = { fg_at(0, 15) }, -- greet
}
local seen = {}
for _, role in ipairs({ "variable", "parameter", "member", "method" }) do
  local fg, group = roles[role][1], roles[role][2]
  assert(fg, role .. " should resolve to a color (" .. group .. ")")
  assert(not seen[fg], ("%s (%s) should not share a color with %s"):format(role, group, tostring(seen[fg])))
  seen[fg] = role
end
assert_equal(roles.method[1], roles.function_name[1], "method calls and function names should share the function color")
assert_equal(roles.variable[1], hl("Normal").fg, "plain variables should use the normal foreground")
assert(roles.member[1] ~= hl("Type").fg, "fields should not share the type color")
assert(not hl("@variable.member").bold and hl("Type").bold, "types should be bold and fields should not")

-- sethy-vim の上書きが sethy-default に残らない
vim.cmd("colorscheme sethy-default")
assert_equal(hl("String").fg, tonumber("b3f6c0", 16), "String should return to the default color after switching from sethy-vim")
assert_equal(hl("@variable").fg, hl("Normal").fg, "@variable should not keep sethy-vim's override after switching")
