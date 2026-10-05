-- Vim の標準 colorscheme (vim) をベースに、ネオンに近い色だけを少し抑えたもの。
-- 構文色・黄色の行番号・青い ~・黄色の検索・DarkCyan の括弧など、vim の見た目はほぼそのまま残す。
-- UI 面 (透過・float・picker) は lua/Sethy/colors/ui.lua で他の自前テーマと揃える。
-- ピンク系 (vim の PreProc / Title) は文字のアクセントにだけ残し、
-- vim の Pmenu (Magenta) のように面で出る場所には使わない。
-- ターミナル側 (ghostty / wezterm) の黒背景を透かす前提なので dark に固定している。

vim.o.background = "dark"
-- vim が定義している link (Treesitter / LSP / Diagnostic など) をそのまま使うため、先に読み込む
vim.cmd.runtime("colors/vim.lua")
vim.g.colors_name = "sethy-vim"

local c = {
    -- 中立色は vim に合わせて青みのない灰色。本文は灰色に寄せずはっきりした白にする
    black = "#000000",
    grey1 = "#1c1c1c",
    grey2 = "#303030",
    grey3 = "#3a3a3a",
    grey4 = "#585858",
    grey5 = "#8a8a8a",
    grey7 = "#d0d0d0",
    white = "#ffffff",

    -- vim の構文色。右は元の値。ネオンに近いものだけ少し抑えている
    blue = "#80a0ff", -- Comment    #80a0ff
    salmon = "#ffa0a0", -- Constant   #ffa0a0
    cyan = "#48eaea", -- Identifier #40ffff
    yellow = "#fafa5a", -- Statement  #ffff60
    green = "#5ff55f", -- Type       #60ff60
    orange = "#f5a623", -- Special    Orange
    magenta = "#ee88ee", -- PreProc    #ff80ff / Title Magenta
    red = "#ee4444", -- Red

    line_yellow = "#d7d75f", -- LineNr     Yellow
    nontext_blue = "#5f5fff", -- NonText    Blue
    dark_cyan = "#008b8b", -- MatchParen DarkCyan
}

require("Sethy.colors.ui").apply({
    fg = c.white,
    fg_strong = c.white,
    fg_sub = c.grey7,
    fg_muted = c.grey5,
    faint = c.grey2,
    border = c.grey4,
    bg_subtle = c.grey1,
    bg_sel = c.grey3,
    accent = c.blue,
    accent_alt = c.cyan,
    search_fg = c.black,
    search_bg = c.yellow,
    cur_search_fg = c.black,
    cur_search_bg = c.orange,
})

require("Sethy.colors.ui").set({
    -- 構文
    Comment = { fg = c.blue },
    Constant = { fg = c.salmon },
    Special = { fg = c.orange },
    Identifier = { fg = c.cyan },
    Statement = { fg = c.yellow, bold = true },
    PreProc = { fg = c.magenta },
    Type = { fg = c.green, bold = true },
    Underlined = { fg = c.blue, underline = true },
    Title = { fg = c.magenta, bold = true },
    Todo = { fg = "#0000c0", bg = c.yellow },
    Error = { fg = c.white, bg = "#b22222" },

    -- vim の UI の特徴
    LineNr = { fg = c.line_yellow, bg = "none" },
    CursorLineNr = { fg = c.yellow, bg = "none", bold = true },
    NonText = { fg = c.nontext_blue, bold = true },
    EndOfBuffer = { link = "NonText" },
    SpecialKey = { fg = "#40c0c0" },
    Directory = { fg = c.cyan },
    MatchParen = { bg = c.dark_cyan },
    Visual = { fg = "#d3d3d3", bg = "#575757" },
    Folded = { fg = c.cyan, bg = "none" },
    FoldColumn = { fg = c.cyan, bg = "none" },
    CursorLine = { bg = c.grey2 },
    CursorColumn = { bg = c.grey2 },
    -- colorcolumn = 80 で縦一列に出るので、vim の DarkRed を暗く落とす
    ColorColumn = { bg = "#3a1414" },
    Conceal = { fg = "#d3d3d3", bg = "none" },

    -- メッセージ
    ErrorMsg = { fg = c.white, bg = "#b22222" },
    WarningMsg = { fg = c.red },
    MoreMsg = { fg = "#3cb371", bold = true },
    Question = { fg = "#44dd44", bold = true },
    WildMenu = { fg = c.black, bg = c.yellow },
    -- vim は terminal の statusline を明るい緑の面にするので、通常の statusline に揃える
    StatusLineTerm = { link = "StatusLine" },
    StatusLineTermNC = { link = "StatusLineNC" },

    -- diff: vim の色相 (DarkBlue / DarkMagenta / DarkCyan / Red) のまま暗くする
    DiffAdd = { bg = "#1c2a5c" },
    DiffChange = { bg = "#33213f" },
    DiffDelete = { fg = c.nontext_blue, bg = "#123b3b", bold = true },
    DiffText = { bg = "#6b1f1f", bold = true },
    Added = { fg = "#44cc44" },
    Changed = { fg = "#3a8ee6" },
    Removed = { fg = c.red },

    DiagnosticError = { fg = c.red },
    DiagnosticWarn = { fg = c.orange },
    DiagnosticInfo = { fg = "#add8e6" },
    DiagnosticHint = { fg = "#d3d3d3" },
    DiagnosticOk = { fg = "#90ee90" },
    DiagnosticUnderlineError = { sp = c.red, underline = true },
    DiagnosticUnderlineWarn = { sp = c.orange, underline = true },
    DiagnosticUnderlineInfo = { sp = "#add8e6", underline = true },
    DiagnosticUnderlineHint = { sp = "#d3d3d3", underline = true },
    DiagnosticUnderlineOk = { sp = "#90ee90", underline = true },
    DiagnosticDeprecated = { sp = c.red, strikethrough = true },

    SpellBad = { sp = c.red, undercurl = true },
    SpellCap = { sp = c.blue, undercurl = true },
    SpellLocal = { sp = c.cyan, undercurl = true },
    SpellRare = { sp = c.magenta, undercurl = true },
})
