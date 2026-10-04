-- Neovim 標準の colorscheme (default) をベースに、他テーマと同じ透過・float・picker の見た目を足したもの。
-- 構文ハイライトは default のまま残し、UI 面だけを lua/Sethy/colors/ui.lua で上書きする。
-- ターミナル側 (ghostty / wezterm) の黒背景を透かす前提なので dark に固定している。

vim.o.background = "dark"
vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
end
vim.g.colors_name = "sethy-default"

-- default が使っている Nvim* パレットと同じ値
local c = {
    dark1 = "#07080d",
    dark2 = "#14161b",
    dark3 = "#2c2e33",
    dark4 = "#4f5258",
    light1 = "#eef1f8",
    light2 = "#e0e2ea",
    light3 = "#c4c6cd",
    light4 = "#9b9ea4",
    blue = "#a6dbff",
    cyan = "#8cf8f7",
    green = "#b3f6c0",
    magenta = "#ffcaff",
    red = "#ffc0b9",
    yellow = "#fce094",
    dark_blue = "#004c73",
    dark_yellow = "#6b5300",
}

require("Sethy.colors.ui").apply({
    fg = c.light2,
    fg_strong = c.light1,
    fg_sub = c.light3,
    fg_muted = c.light4,
    faint = c.dark3,
    border = c.dark4,
    bg_subtle = c.dark2,
    bg_sel = c.dark3,
    accent = c.blue,
    accent_alt = c.cyan,
    search_fg = c.light1,
    search_bg = c.dark_blue,
    cur_search_fg = c.dark1,
    cur_search_bg = c.yellow,
})
