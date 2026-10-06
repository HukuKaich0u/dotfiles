-- Vim の標準 colorscheme (vim) と Neovim 標準の default を混ぜたもの。
-- 骨格は default に倣って白を多くし (キーワード・演算子・変数・引数は白、コメントは灰色、文字列は緑)、
-- 色は 白・緑・水色・赤・青 の5系統が混ざるように割り当てる
-- (文字列=緑、フィールド=水色、型と数値・定数=赤、関数=濃く淡い青、組み込み=vim のオレンジ)。
-- vim の黄色は行番号と検索などの UI にだけ使い、コードには使わない (同じ黄色が行番号とコードの両方に出ると黄色が多く見えるため)。
-- 色の濃さは vim の GUI 用の淡い値ではなく、端末で vim を動かしたときの ANSI 色 (WezTerm 標準の #55cc55 など) に合わせている。
-- 構文色・黄色の行番号・青い ~・黄色の検索・DarkCyan の括弧など、vim の見た目はほぼそのまま残す。
-- UI 面 (透過・float・picker) は lua/Sethy/colors/ui.lua で他の自前テーマと揃える。
-- ピンク系 (vim の PreProc / Title) は、デコレータ・マクロ・見出しなど出現頻度の低いアクセントにだけ残し、
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

    -- vim の構文色。右は vim (GUI) の値。色相は保ち、パステル寄りのものは濃くしている
    blue = "#7090ff", -- Comment    #80a0ff (コメントには使わず、リンクや UI のアクセントに使う)
    red_soft = "#ff6b6b", -- Constant   #ffa0a0 (型にも使う。サーモンだとピンクに見えるので赤に寄せた)
    cyan = "#40e0e0", -- Identifier #40ffff
    yellow = "#fafa5a", -- Statement  #ffff60 (コードには使わず、行番号・検索などの UI に使う)
    green = "#55cc55", -- Type       #60ff60 (WezTerm 標準の ANSI green。default に倣い文字列に使う)
    orange = "#f5a623", -- Special    Orange
    pink = "#ff5faf", -- PreProc    #ff80ff / Title Magenta (紫を抑えた ANSI 256 色の 205)
    red = "#ee4444", -- Red

    -- default 由来の色
    comment = "#9b9ea4", -- Comment: default の NvimLightGrey4
    member = "#87d7ff", -- フィールド・プロパティ: default の水色 (NvimLightBlue) を ANSI 寄りに濃くしたもの
    func_blue = "#7b9cff", -- 関数・メソッド: フィールドの水色と並べて区別できる、濃く淡い青

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
    Comment = { fg = c.comment },
    Constant = { fg = c.red_soft },
    String = { fg = c.green },
    -- true / false は設定ファイルに頻出し、サーモンだとピンクが多く見えるので default と同じく白にする
    Boolean = { fg = c.white },
    Character = { link = "String" },
    Special = { fg = c.orange },
    Identifier = { fg = c.cyan },
    Statement = { fg = c.white, bold = true },
    PreProc = { fg = c.pink },
    Type = { fg = c.red_soft, bold = true },
    Underlined = { fg = c.blue, underline = true },
    Title = { fg = c.pink, bold = true },
    Todo = { fg = "#0000c0", bg = c.yellow },
    Error = { fg = c.white, bg = "#b22222" },

    -- vim.lua は変数・引数・プロパティ・関数をすべて Identifier (シアン) に link するので、
    -- 変数と関数の区別がつかない。変数・引数は白、フィールドは水色、関数は青に分ける。
    Function = { fg = c.func_blue },
    ["@variable"] = { fg = c.white },
    ["@variable.builtin"] = { link = "Special" }, -- self / this
    ["@variable.parameter"] = { link = "@variable" },
    ["@variable.member"] = { fg = c.member },
    ["@property"] = { link = "@variable.member" },
    -- JSON / TOML / YAML などのデータファイルはキーが大半を占めるので、キーは白にして値 (文字列の緑など) と分ける
    ["@property.json"] = { fg = c.white },
    ["@property.jsonc"] = { link = "@property.json" },
    ["@property.json5"] = { link = "@property.json" },
    ["@property.toml"] = { link = "@property.json" },
    ["@property.yaml"] = { link = "@property.json" },
    ["@module"] = { link = "Structure" },
    -- string / number などの組み込み型は Neovim 既定だと Special (オレンジ) になる。型と同じ赤の太字に揃える
    ["@type.builtin"] = { link = "Type" },
    -- 括弧やカンマは vim だと Delimiter (Special のオレンジ) になり画面がうるさいので、白に近い灰色にする
    ["@punctuation"] = { fg = c.grey7 },
    ["@punctuation.special"] = { link = "Special" }, -- 文字列補間の ${} など

    -- default に倣い、キーワード (local / function / if / return …) は白の太字、演算子は白にする。
    -- 制御フローのキーワードも vim.lua の link (Conditional / Repeat → Statement) で同じ白の太字になる
    Operator = { fg = c.white },
    ["@keyword"] = { fg = c.white, bold = true },
    ["@keyword.function"] = { link = "@keyword" },
    ["@keyword.modifier"] = { link = "@keyword" },
    ["@keyword.type"] = { link = "@keyword" },
    -- import / export / from は vim だと PreProc (ピンク) になるが、どのファイルにも何度も出るので宣言系と同じ白にする。
    -- ピンクはデコレータ・属性・マクロ・プリプロセッサ指令 (PreProc に link したまま) に残す
    ["@keyword.import"] = { link = "@keyword" },

    -- LSP の semantic token は Treesitter より優先されるので、同じ割り当てに揃える
    ["@lsp.type.variable"] = { link = "@variable" },
    ["@lsp.type.parameter"] = { link = "@variable.parameter" },
    ["@lsp.type.property"] = { link = "@variable.member" },
    ["@lsp.type.namespace"] = { link = "@module" },

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
    -- colorcolumn = 80 で縦一列に出るので、vim の DarkRed ではなく CursorLine より一段暗い灰色にする
    ColorColumn = { bg = "#262626" },
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
    SpellRare = { sp = c.pink, undercurl = true },
})
