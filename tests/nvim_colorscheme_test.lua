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

-- sethy-vim で vim の色を残すグループと、default に倣うグループ
local vim_groups = { "Constant", "Identifier", "Statement", "Special" }
local default_groups = { "Comment", "String" }

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
for _, group in ipairs(vim_groups) do
  vim_fg[group] = hl(group).fg
end

vim.cmd("colorscheme default")
local default_fg = {}
for _, group in ipairs(default_groups) do
  default_fg[group] = hl(group).fg
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

local function hue_diff(a, b)
  local diff = math.abs(hue(a) - hue(b))
  return math.min(diff, 360 - diff)
end

-- vim の色を残すグループは vim の色相を保つ
for _, group in ipairs(vim_groups) do
  local fg = hl(group).fg
  assert(fg, group .. " should have a foreground color")
  assert(hue_diff(fg, vim_fg[group]) <= 10, ("%s should keep vim's hue: #%06x vs #%06x"):format(group, fg, vim_fg[group]))
end

-- default に倣うグループ: コメントは default と同じ灰色、文字列は default と同じ緑の色相 (濃さは ANSI 寄り)
assert_equal(hl("Comment").fg, default_fg.Comment, "Comment should use default's grey")
assert(hue_diff(hl("String").fg, default_fg.String) <= 15, ("String should keep default's green hue: #%06x"):format(hl("String").fg))
-- 型は default と同じく本文色。太字で見分ける
assert_equal(hl("Type").fg, hl("Normal").fg, "Type should use the normal foreground like default")
assert_equal(hl("Type").bold, true, "Type should be bold")

-- ピンク (PreProc) は vim のマゼンタより紫を抑え、import / export には使わない
do
  local h = hue(hl("PreProc").fg)
  assert(h >= 320 and h <= 345, ("PreProc should be a pink with less purple, got #%06x (hue %d)"):format(hl("PreProc").fg, h))
  assert_equal(hl("@keyword.import").fg, hl("Normal").fg, "import / export should use white instead of pink")
  assert_equal(hl("@keyword.import").bold, true, "import / export should be bold like other declaration keywords")
  assert_equal(hl("@attribute").fg, hl("PreProc").fg, "decorators / attributes should keep the pink accent")
end

-- true / false は default と同じく白 (サーモンだと設定ファイルがピンクだらけに見える)。数値は vim のサーモンのまま
assert_equal(hl("Boolean").fg, hl("Normal").fg, "booleans should use white")
assert_equal(hl("Number").fg, hl("Constant").fg, "numbers should keep vim's salmon")

-- データファイルのキーは白にして、値の色と分ける
for _, lang in ipairs({ "json", "jsonc", "json5", "toml", "yaml" }) do
  assert_equal(hl("@property." .. lang).fg, hl("Normal").fg, lang .. " keys should use white")
end
assert(hl("@property").fg ~= hl("Normal").fg, "properties in code should keep their own color")

-- ネオンに近い色だけは vim より抑える
for _, group in ipairs({ "Identifier", "Statement" }) do
  local r, g, b = rgb(hl(group).fg)
  local vr, vg, vb = rgb(vim_fg[group])
  assert(r + g + b < vr + vg + vb, group .. " should be dimmer than vim's original")
end

assert_equal(vim.api.nvim_get_hl(0, { name = "@function" }).link, "Function", "@function should keep vim's link")

-- 実際のコードで、変数・フィールド・関数呼び出しが別の色になる。引数は default と同じく変数と同じ白
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
for _, role in ipairs({ "variable", "member", "method" }) do
  local fg, group = roles[role][1], roles[role][2]
  assert(fg, role .. " should resolve to a color (" .. group .. ")")
  assert(not seen[fg], ("%s (%s) should not share a color with %s"):format(role, group, tostring(seen[fg])))
  seen[fg] = role
end
assert_equal(roles.method[1], roles.function_name[1], "method calls and function names should share the function color")
assert_equal(roles.variable[1], hl("Normal").fg, "plain variables should use the normal foreground")
assert(roles.parameter[1], "parameter should resolve to a color (" .. roles.parameter[2] .. ")")
assert_equal(roles.parameter[1], roles.variable[1], "parameters should use the same white as variables")
assert(roles.member[1] ~= hl("String").fg, "fields should not share the string color")

-- 宣言系のキーワードと演算子は白、制御フローのキーワードだけ vim の黄色
local function hl_at(row, col)
  local _, group = fg_at(row, col)
  return hl(group), group
end
for _, pos in ipairs({ { 0, 0 }, { 0, 6 } }) do -- local / function
  local h, group = hl_at(pos[1], pos[2])
  assert_equal(h.fg, hl("Normal").fg, group .. " should use white like Neovim's default")
  assert_equal(h.bold, true, group .. " should stay bold")
end
assert_equal(hl_at(2, 2).fg, hl("Statement").fg, "return should keep vim's yellow")
assert_equal(hl_at(1, 13).fg, hl("Normal").fg, "operators should use white")

-- sethy-vim の上書きが sethy-default に残らない
vim.cmd("colorscheme sethy-default")
assert_equal(hl("String").fg, tonumber("b3f6c0", 16), "String should return to the default color after switching from sethy-vim")
assert_equal(hl("@variable").fg, hl("Normal").fg, "@variable should not keep sethy-vim's override after switching")
