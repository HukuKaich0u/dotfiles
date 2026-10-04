-- colors/ 配下の自前テーマで共通の UI 上書き。
-- 透過・float・補完メニュー・picker などの見た目を揃え、構文ハイライトは各テーマに任せる。
-- 各テーマは自分のパレットを下の役割名に割り当てて apply を呼ぶ。
--
-- 役割:
--   fg / fg_strong / fg_sub / fg_muted : 本文 / 強調 / 一段薄い / さらに薄い文字
--   faint                              : EndOfBuffer や区切り線などほぼ見えなくていい線
--   border                             : float や picker の枠
--   bg_subtle / bg_sel                 : 薄い面 (CursorLine など) / 選択中の面
--   accent / accent_alt                : タイトル・入力枠 / 補完の種類やトグル
--   search_fg / search_bg              : 検索ヒット
--   cur_search_fg / cur_search_bg      : 現在の検索ヒット

local M = {}

local none = "none"

---@param c table<string, string>
function M.highlights(c)
    return {
        -- 透過: エディタ本体と周辺の背景を抜く
        Normal = { fg = c.fg, bg = none },
        NormalNC = { fg = c.fg, bg = none },
        EndOfBuffer = { fg = c.faint, bg = none },
        SignColumn = { bg = none },
        FoldColumn = { fg = c.border, bg = none },
        LineNr = { fg = c.border, bg = none },
        CursorLineNr = { fg = c.fg_sub, bg = none, bold = true },
        Folded = { fg = c.fg_muted, bg = none },
        MsgArea = { bg = none },
        StatusLine = { fg = c.fg_sub, bg = none },
        StatusLineNC = { fg = c.border, bg = none },
        TabLine = { fg = c.fg_muted, bg = none },
        TabLineFill = { bg = none },
        TabLineSel = { fg = c.fg_strong, bg = c.bg_sel, bold = true },
        WinBar = { fg = c.fg_muted, bg = none, bold = true },
        WinBarNC = { fg = c.border, bg = none },
        WinSeparator = { fg = c.faint, bg = none },

        -- 行・選択系: ColorColumn などは薄い面に揃える
        CursorLine = { bg = c.bg_subtle },
        ColorColumn = { bg = c.bg_subtle },
        Visual = { bg = c.bg_sel },

        -- float: 背景は抜いて、枠と title で境界を見せる
        NormalFloat = { fg = c.fg, bg = none },
        FloatBorder = { fg = c.border, bg = none },
        FloatTitle = { fg = c.accent, bg = none, bold = true },
        FloatFooter = { fg = c.fg_muted, bg = none },

        -- 補完メニュー: reverse や色付きの面をやめて他テーマと揃える
        Pmenu = { fg = c.fg_sub, bg = none },
        PmenuSel = { fg = c.fg_strong, bg = c.bg_sel, bold = true },
        PmenuSbar = { bg = c.bg_subtle },
        PmenuThumb = { bg = c.border },
        PmenuKind = { fg = c.accent_alt, bg = none },
        PmenuExtra = { fg = c.fg_muted, bg = none },

        Search = { fg = c.search_fg, bg = c.search_bg },
        CurSearch = { fg = c.cur_search_fg, bg = c.cur_search_bg, bold = true },
        IncSearch = { link = "CurSearch" },

        -- lazy / mason は他テーマと同じく薄い panel 背景を残す
        LazyNormal = { fg = c.fg_sub, bg = c.bg_subtle },
        MasonNormal = { fg = c.fg_sub, bg = c.bg_subtle },

        TelescopeNormal = { fg = c.fg, bg = none },
        TelescopeBorder = { fg = c.border, bg = none },
        TelescopePromptNormal = { fg = c.fg, bg = none },
        TelescopePromptBorder = { fg = c.accent, bg = none },
        TelescopePromptTitle = { fg = c.accent, bg = none, bold = true },
        TelescopeResultsNormal = { fg = c.fg_sub, bg = none },
        TelescopeResultsBorder = { fg = c.border, bg = none },
        TelescopeResultsTitle = { fg = c.fg_muted, bg = none },
        TelescopePreviewNormal = { bg = none },
        TelescopePreviewBorder = { fg = c.border, bg = none },
        TelescopePreviewTitle = { fg = c.fg_muted, bg = none },
        TelescopeTitle = { fg = c.accent, bg = none, bold = true },
        TelescopeSelection = { fg = c.fg_strong, bg = c.bg_sel, bold = true },

        SnacksPickerFile = { fg = c.fg_strong },
        SnacksPickerDirectory = { fg = c.fg_muted },
        SnacksPickerDir = { fg = c.fg_muted },
        SnacksPickerPathHidden = { fg = c.border },
        SnacksPickerPathIgnored = { fg = c.border },
        SnacksPickerListCursorLine = { fg = c.fg_strong, bg = c.bg_sel },
        SnacksPickerBorder = { fg = c.border, bg = none },
        SnacksPickerTitle = { fg = c.accent, bg = none, bold = true },
        SnacksPickerBoxBorder = { fg = c.border, bg = none },
        SnacksPickerBoxTitle = { fg = c.accent, bg = none, bold = true },
        SnacksPickerInputBorder = { fg = c.accent, bg = none },
        SnacksPickerInputTitle = { fg = c.accent, bg = none, bold = true },
        SnacksPickerToggle = { fg = c.accent_alt, bg = none },
        SnacksPickerToggleHidden = { fg = c.accent_alt, bg = none },
        SnacksPickerToggleIgnored = { fg = c.accent_alt, bg = none },

        BlinkCmpMenu = { fg = c.fg_sub, bg = none },
        BlinkCmpMenuBorder = { fg = c.border, bg = none },
        BlinkCmpMenuSelection = { fg = c.fg_strong, bg = c.bg_sel, bold = true },
        BlinkCmpDoc = { fg = c.fg, bg = none },
        BlinkCmpDocBorder = { fg = c.border, bg = none },
        BlinkCmpSignatureHelp = { fg = c.fg, bg = none },
        BlinkCmpSignatureHelpBorder = { fg = c.border, bg = none },

        NoiceCmdlinePopup = { fg = c.fg, bg = none },
        NoiceCmdlinePopupBorder = { fg = c.accent, bg = none },
        NoicePopup = { fg = c.fg, bg = none },
        NoicePopupBorder = { fg = c.border, bg = none },
        NoiceConfirm = { fg = c.fg, bg = none },
        NoiceConfirmBorder = { fg = c.accent, bg = none },

        TroubleNormal = { bg = none },
        TroubleNormalNC = { bg = none },
    }
end

---@param groups table<string, vim.api.keyset.highlight>
function M.set(groups)
    for group, opts in pairs(groups) do
        vim.api.nvim_set_hl(0, group, opts)
    end
end

---@param c table<string, string>
function M.apply(c)
    M.set(M.highlights(c))
end

return M
