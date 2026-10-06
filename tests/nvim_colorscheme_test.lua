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
local vim_groups = { "Constant", "Identifier", "Special" }
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
-- 型は数値・定数と同じ赤の太字
assert_equal(hl("Type").fg, hl("Constant").fg, "Type should share the red with constants")
assert_equal(hl("Type").bold, true, "Type should be bold")

-- 白・緑・水色・赤・青の5系統: 関数は青、フィールドは水色で、互いに区別できる
do
  local fh, mh = hue(hl("Function").fg), hue(hl("@variable.member").fg)
  assert(fh >= 215 and fh <= 235, ("Function should be blue, got #%06x"):format(hl("Function").fg))
  assert(mh >= 190 and mh <= 210, ("fields should be light blue, got #%06x"):format(hl("@variable.member").fg))
  local ch = hue(hl("Constant").fg)
  assert(ch <= 10 or ch >= 350, ("Constant should be red, got #%06x"):format(hl("Constant").fg))
end

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
for _, group in ipairs({ "Identifier" }) do
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

-- キーワードは制御フローも含めて白の太字、演算子は白。黄色は行番号だけに使い、コードには出さない
local function hl_at(row, col)
  local _, group = fg_at(row, col)
  return hl(group), group
end
for _, pos in ipairs({ { 0, 0 }, { 0, 6 }, { 2, 2 } }) do -- local / function / return
  local h, group = hl_at(pos[1], pos[2])
  assert_equal(h.fg, hl("Normal").fg, group .. " should use white like Neovim's default")
  assert_equal(h.bold, true, group .. " should stay bold")
end
assert(hl("Statement").fg ~= hl("CursorLineNr").fg, "Statement should not share the line number yellow")
for _, group in ipairs({ "Statement", "Conditional", "Repeat", "Keyword", "Operator", "@keyword.return", "@keyword.operator", "@keyword.coroutine" }) do
  local h = hue(hl(group).fg)
  local r, g, b = rgb(hl(group).fg)
  assert(not (h >= 40 and h <= 70 and math.max(r, g, b) - math.min(r, g, b) > 60), ("%s should not be yellow in code, got #%06x"):format(group, hl(group).fg))
end
assert_equal(hl_at(1, 13).fg, hl("Normal").fg, "operators should use white")

-- Markdown もコードと同じ5系統の色を使い、ftplugin の VS Code 風の色で上書きされない
local markdown_ftplugin = repo_root .. "/nix/modules/home/assets/nvim/after/ftplugin/markdown.lua"
local md_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_set_current_buf(md_buf)
vim.cmd.source(markdown_ftplugin)
local code_colors = {}
for _, group in ipairs({ "Normal", "String", "Function", "Type", "Special", "@variable.member" }) do
  code_colors[hl(group).fg] = group
end
for level = 1, 6 do
  local group = "@markup.heading." .. level .. ".markdown"
  assert(code_colors[hl(group).fg], ("%s should use a code color, got %s"):format(group, vim.inspect(hl(group).fg)))
  assert_equal(hl(group).bold, true, group .. " should be bold")
end
assert_equal(hl("@markup.raw.markdown_inline").fg, hl("String").fg, "inline code should use the string green")
assert_equal(hl("@markup.link.label.markdown_inline").fg, hl("@variable.member").fg, "link labels should use the field light blue")
assert_equal(hl("@markup.quote.markdown").fg, hl("Comment").fg, "quotes should use the comment grey")
-- render-markdown のアイコンは言語なしの基底グループに link するので、そちらもコードの色に揃う
assert_equal(hl("@markup.list.checked").fg, hl("String").fg, "checked checkboxes should use the string green")
assert_equal(hl("@markup.quote").fg, hl("Comment").fg, "quote bars should use the comment grey")

-- sethy-vim の上書きが sethy-default に残らない
vim.cmd("colorscheme sethy-default")
assert_equal(hl("String").fg, tonumber("b3f6c0", 16), "String should return to the default color after switching from sethy-vim")
assert_equal(hl("@variable").fg, hl("Normal").fg, "@variable should not keep sethy-vim's override after switching")

-- sethy-vim 以外では、これまでどおり ftplugin の VS Code 風の色が当たる
vim.cmd.source(markdown_ftplugin)
assert_equal(hl("@markup.heading.1.markdown").fg, tonumber("569CD6", 16), "other colorschemes should keep the ftplugin markdown colors")

-- 自前テーマの UI は構文用のグループに引きずられず、UI の役割の色に揃う
local ui = require("Sethy.colors.ui")
for _, scheme in ipairs({ "sethy-vim", "sethy-default" }) do
  vim.cmd("colorscheme " .. scheme)
  -- snacks は ColorScheme の後に既定の link を default = true で足すので、先に定義した色が残ることを確かめる
  vim.api.nvim_set_hl(0, "SnacksPickerTree", { link = "LineNr", default = true })
  assert_equal(hl("SnacksPickerTree").fg, hl("FloatBorder").fg, scheme .. ": explorer tree lines should use the border grey")
  for _, group in ipairs({ "SnacksPickerMatch", "SnacksPickerPrompt", "SnacksDashboardHeader" }) do
    assert_equal(hl(group).fg, hl("FloatTitle").fg, scheme .. ": " .. group .. " should use the UI accent")
  end
  for _, group in ipairs({ "SnacksPickerTotals", "SnacksPickerGitStatusUntracked" }) do
    assert_equal(hl(group).fg, hl("FloatFooter").fg, scheme .. ": " .. group .. " should use the muted text color")
    assert(not hl(group).bold, scheme .. ": " .. group .. " should not be bold")
  end

  local palette = ui.palette()
  assert(palette, scheme .. ": the palette should be available for lualine")
  for _, role in ipairs({ "mode_fg", "mode_normal", "mode_insert", "mode_visual", "mode_replace", "mode_command" }) do
    assert(palette[role], scheme .. ": palette should define " .. role)
  end
end

-- sethy-vim の lualine のモード表示は、コードで使っている色から選ぶ
vim.cmd("colorscheme sethy-vim")
do
  local palette = ui.palette()
  local function color(name)
    return tonumber(palette[name]:sub(2), 16)
  end
  assert_equal(color("mode_normal"), hl("Function").fg, "normal mode should use the function blue")
  assert_equal(color("mode_insert"), hl("String").fg, "insert mode should use the string green")
  assert_equal(color("mode_visual"), hl("@variable.member").fg, "visual mode should use the field light blue")
  assert_equal(color("mode_replace"), hl("Constant").fg, "replace mode should use the type / constant red")
  assert_equal(color("mode_command"), hl("Special").fg, "command mode should use the builtin orange")
end

-- 自前テーマ以外ではパレットを返さず、lualine は従来の色を使う
vim.cmd("colorscheme default")
assert_equal(ui.palette(), nil, "non-sethy colorschemes should not expose a palette")
