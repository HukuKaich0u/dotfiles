-- Vim の標準 colorscheme (vim) をベースに、色の刺激を抑えたもの。
-- 色の割り当て (Comment は青、Statement は黄、Type は緑 …) は vim のまま残し、
-- 原色に近い値だけ彩度と明度を落とす。UI 面は lua/Sethy/colors/ui.lua で他の自前テーマと揃える。
-- ピンク系 (vim の PreProc / Title / Pmenu) は include や見出しなどのアクセントにだけ残し、
-- 補完メニューのように面で出る場所には使わない。
-- ターミナル側 (ghostty / wezterm) の黒背景を透かす前提なので dark に固定している。

vim.o.background = "dark"
-- vim が定義している link (Treesitter / LSP / Diagnostic など) をそのまま使うため、先に読み込む
vim.cmd.runtime("colors/vim.lua")
vim.g.colors_name = "sethy-vim"

local c = {
    black = "#0b0c10",
    dark2 = "#17191e",
    dark3 = "#2b2e35",
    dark4 = "#50545c",
    light1 = "#ececec",
    light2 = "#d4d4d4",
    light3 = "#b6b6b8",
    light4 = "#8c8e93",

    -- vim の構文色を落ち着かせた値。右は元の値
    blue = "#8496c9", -- Comment    #80a0ff
    cyan = "#79c2c2", -- Identifier #40ffff
    yellow = "#dccb7a", -- Statement  #ffff60
    green = "#8cc788", -- Type       #60ff60
    coral = "#dfa48f", -- Constant   #ffa0a0 (ピンク寄りから橙寄りへ)
    orange = "#d6a066", -- Special    Orange
    orchid = "#be98cf", -- PreProc    #ff80ff (アクセント用)
    red = "#e0857b", -- Error / Removed

    blue_bright = "#9fb3e6",
    search_bg = "#4a4422",
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
    accent = c.blue_bright,
    accent_alt = c.cyan,
    search_fg = c.light1,
    search_bg = c.search_bg,
    cur_search_fg = c.black,
    cur_search_bg = c.yellow,
})

require("Sethy.colors.ui").set({
    -- 構文
    Comment = { fg = c.blue },
    Constant = { fg = c.coral },
    Special = { fg = c.orange },
    Identifier = { fg = c.cyan },
    Statement = { fg = c.yellow, bold = true },
    PreProc = { fg = c.orchid },
    Type = { fg = c.green, bold = true },
    Underlined = { fg = c.blue_bright, underline = true },
    Title = { fg = c.orchid, bold = true },
    Todo = { fg = c.black, bg = c.yellow, bold = true },
    Error = { fg = c.red, bold = true },
    -- vim は変数を全部 Identifier (シアン) にするので画面がシアンで埋まる。素の変数だけ本文色にする
    ["@variable"] = { fg = c.light2 },

    -- vim らしさとして残す小さなアクセント
    CursorLineNr = { fg = c.yellow, bg = "none", bold = true },
    NonText = { fg = "#4c5878" },
    SpecialKey = { fg = "#5f8f8f" },
    Directory = { fg = c.cyan },
    MatchParen = { bg = "#2d4b4b", bold = true },
    CursorColumn = { bg = c.dark2 },
    Conceal = { fg = c.light4, bg = "none" },

    -- メッセージ
    ErrorMsg = { fg = c.red, bold = true },
    WarningMsg = { fg = c.red },
    MoreMsg = { fg = c.green, bold = true },
    Question = { fg = c.green, bold = true },
    WildMenu = { fg = c.black, bg = c.yellow },
    -- vim は terminal の statusline を明るい緑の面にするので、通常の statusline に揃える
    StatusLineTerm = { link = "StatusLine" },
    StatusLineTermNC = { link = "StatusLineNC" },

    -- diff: vim の色相 (青 / 紫 / シアン / 赤) を暗い面に置き換える
    DiffAdd = { bg = "#1f3326" },
    DiffChange = { bg = "#252b40" },
    DiffDelete = { fg = "#8a4a4a", bg = "#2e1c1e" },
    DiffText = { bg = "#354470", bold = true },
    Added = { fg = c.green },
    Changed = { fg = c.blue_bright },
    Removed = { fg = c.red },

    DiagnosticError = { fg = c.red },
    DiagnosticWarn = { fg = c.orange },
    DiagnosticInfo = { fg = c.blue_bright },
    DiagnosticHint = { fg = c.light4 },
    DiagnosticOk = { fg = c.green },
    DiagnosticUnderlineError = { sp = c.red, underline = true },
    DiagnosticUnderlineWarn = { sp = c.orange, underline = true },
    DiagnosticUnderlineInfo = { sp = c.blue_bright, underline = true },
    DiagnosticUnderlineHint = { sp = c.light4, underline = true },
    DiagnosticUnderlineOk = { sp = c.green, underline = true },
    DiagnosticDeprecated = { sp = c.red, strikethrough = true },

    SpellBad = { sp = c.red, undercurl = true },
    SpellCap = { sp = c.blue_bright, undercurl = true },
    SpellLocal = { sp = c.cyan, undercurl = true },
    SpellRare = { sp = c.orchid, undercurl = true },
})
