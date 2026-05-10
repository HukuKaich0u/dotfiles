local function get_highlight(name)
    local ok, highlight = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
    return ok and highlight or {}
end

local function merge_highlight(name, opts)
    vim.api.nvim_set_hl(0, name, vim.tbl_extend("force", get_highlight(name), opts))
end

local function apply_snacks_picker_highlights(colors)
    local normal = get_highlight("Normal")
    local comment = get_highlight("Comment")
    local search = get_highlight("Search")
    local cursorline = get_highlight("CursorLine")

    local file_fg = colors and colors.fg_bright or normal.fg
    local dir_fg = colors and colors.fg or comment.fg or normal.fg
    local muted_fg = colors and colors.muted or comment.fg or dir_fg
    local selection_bg = colors and colors.search or search.bg or cursorline.bg
    local selection_fg = colors and colors.fg_bright or search.fg or normal.fg

    local highlights = {
        SnacksPickerFile = { fg = file_fg },
        SnacksPickerDirectory = { fg = dir_fg },
        SnacksPickerDir = { fg = dir_fg },
        SnacksPickerPathHidden = { fg = muted_fg },
        SnacksPickerPathIgnored = { fg = muted_fg },
        SnacksPickerListCursorLine = { bg = selection_bg, fg = selection_fg },
        SnacksPickerBoxBorder = { bg = "none" },
        SnacksPickerBoxTitle = { bg = "none" },
        SnacksPickerInputBorder = { bg = "none" },
        SnacksPickerInputTitle = { bg = "none" },
        SnacksPickerToggle = { bg = "none" },
        SnacksPickerToggleHidden = { bg = "none" },
        SnacksPickerToggleIgnored = { bg = "none" },
    }

    for group, opts in pairs(highlights) do
        merge_highlight(group, opts)
    end
end

return {
    -- NOTE: NVCode color schemes
    {
        "ChristianChiarulli/nvcode-color-schemes.vim",
        config = function()
            vim.g.nvcode_termcolors = 256

            local transparent_themes = {
                nvcode = true,
                onedark = true,
                nord = true,
                aurora = true,
                palenight = true,
                snazzy = true,
                xoria = true,
            }

            local palette = {
                fg = "#bbc2cf",
                fg_bright = "#e6edf3",
                muted = "#7f848e",
                comment = "#8a9099",
                panel = "#1f2430",
                panel_alt = "#252b39",
                border = "#3b4261",
                accent = "#7aa2f7",
                search = "#33467c",
            }

            local function apply_nvcode_highlights()
                if not transparent_themes[vim.g.colors_name] then
                    apply_snacks_picker_highlights()
                    return
                end

                local highlights = {
                    Normal = { bg = "none" },
                    NormalNC = { bg = "none" },
                    EndOfBuffer = { bg = "none" },
                    ColorColumn = { bg = palette.panel },
                    SignColumn = { bg = "none" },
                    NormalFloat = { bg = "none" },
                    FloatBorder = { bg = "none", fg = palette.border },
                    FloatTitle = { bg = "none", fg = palette.accent, bold = true },
                    Pmenu = { bg = "none", fg = palette.fg },
                    PmenuSel = { bg = palette.panel_alt, fg = palette.fg_bright, bold = true },
                    PmenuSbar = { bg = palette.panel },
                    PmenuThumb = { bg = palette.accent },
                    StatusLine = { bg = "none", fg = palette.fg },
                    StatusLineNC = { bg = "none", fg = palette.muted },
                    WinSeparator = { bg = "none", fg = palette.border },
                    Comment = { fg = palette.comment },
                    Search = { bg = palette.search, fg = palette.fg_bright },
                    IncSearch = { bg = palette.accent, fg = "#0b1020", bold = true },
                    LazyNormal = { bg = palette.panel, fg = palette.muted },
                    MasonNormal = { bg = palette.panel, fg = palette.muted },
                    TelescopeNormal = { bg = "none", fg = palette.fg },
                    TelescopeBorder = { bg = "none", fg = palette.border },
                    TelescopePromptNormal = { bg = "none", fg = palette.fg },
                    TelescopePromptBorder = { bg = "none", fg = palette.accent },
                    TelescopePromptTitle = { bg = "none", fg = palette.accent, bold = true },
                    TelescopeResultsNormal = { bg = "none", fg = palette.muted },
                    TelescopeResultsBorder = { bg = "none", fg = palette.border },
                    TelescopeResultsTitle = { bg = "none", fg = palette.border },
                    TelescopePreviewBorder = { bg = "none", fg = palette.border },
                    TelescopePreviewTitle = { bg = "none", fg = palette.border },
                    TelescopeTitle = { bg = "none", fg = palette.accent, bold = true },
                    NoiceCmdlinePopup = { bg = "none", fg = palette.fg },
                    NoiceCmdlinePopupBorder = { bg = "none", fg = palette.accent },
                    NoicePopup = { bg = "none", fg = palette.fg },
                    NoicePopupBorder = { bg = "none", fg = palette.border },
                    NoiceConfirm = { bg = "none", fg = palette.fg },
                    NoiceConfirmBorder = { bg = "none", fg = palette.accent },
                }

                for group, opts in pairs(highlights) do
                    merge_highlight(group, opts)
                end

                apply_snacks_picker_highlights(palette)
            end

            local group = vim.api.nvim_create_augroup("SethyNvcodeHighlights", { clear = true })

            vim.api.nvim_create_autocmd("ColorScheme", {
                group = group,
                pattern = "*",
                callback = apply_nvcode_highlights,
            })

            apply_nvcode_highlights()
        end,
    },
    -- NOTE: Moonfly
    {
        "bluz71/vim-moonfly-colors",
        name = "moonfly",
        config = function()
            vim.g.moonflyTransparent = true
            vim.g.moonflyNormalFloat = true
            vim.g.moonflyNormalPmenu = true

            vim.api.nvim_create_autocmd("ColorScheme", {
                pattern = "moonfly",
                callback = function()
                    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
                    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
                    vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
                    vim.api.nvim_set_hl(0, "FloatTitle", { bg = "none" })
                    vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
                    vim.api.nvim_set_hl(0, "PmenuSel", { bg = "#323437", fg = "#e4e4e4" })
                    vim.api.nvim_set_hl(0, "PmenuSbar", { bg = "#080808" })
                    vim.api.nvim_set_hl(0, "PmenuThumb", { bg = "#79dac8" })
                end,
            })
        end,
    },
    -- NOTE: Rose pine
    {
        "rose-pine/neovim",
        name = "rose-pine",
        -- priority = 1000,
        config = function()
            require("rose-pine").setup({
                variant = "main",      -- auto, main, moon, or dawn
                dark_variant = "main", -- main, moon, or dawn
                dim_inactive_windows = false,
                -- disable_background = true,
                -- disable_nc_background = false,
                -- disable_float_background = false,
                -- extend_background_behind_borders = false,
                styles = {
                    bold = true,
                    italic = false,
                    transparency = true,
                },
                highlight_groups = {
                    ColorColumn = { bg = "#1C1C21" },
                    Normal = { bg = "none" },                      -- Main background remains transparent
                    Pmenu = { bg = "none", fg = "#e0def4" },           -- Completion menu background
                    PmenuSel = { bg = "#4a465d", fg = "#f8f5f2" }, -- Highlighted completion item
                    PmenuSbar = { bg = "#191724" },                -- Scrollbar background
                    PmenuThumb = { bg = "#9ccfd8" },               -- Scrollbar thumb
                },
                enable = {
                    terminal = false,
                    legacy_highlights = false, -- Improve compatibility for previous versions of Neovim
                    migrations = true,         -- Handle deprecated options automatically
                },

            })

            -- HACK: set this on the color you want to be persistent
            -- when quit and reopening nvim
            -- vim.cmd("colorscheme rose-pine")
        end,
    },
    -- NOTE: gruvbox
    {
        "ellisonleao/gruvbox.nvim",
        -- priority = 1000 ,
        config = function()
            require("gruvbox").setup({
                terminal_colors = true, -- add neovim terminal colors
                undercurl = true,
                underline = true,
                bold = true,
                italic = {
                    strings = false,
                    emphasis = false,
                    comments = false,
                    folds = false,
                    operators = false,
                },
                strikethrough = true,
                invert_selection = false,
                invert_signs = false,
                invert_tabline = false,
                invert_intend_guides = false,
                inverse = true, -- invert background for search, diffs, statuslines and errors
                contrast = "",  -- can be "hard", "soft" or empty string
                palette_overrides = {},
                overrides = {
                    Pmenu = { bg = "NONE" }, -- Completion menu background
                },
                dim_inactive = false,
                transparent_mode = true,
            })
        end,
    },
    -- NOTE: Kanagwa
    {
        "rebelot/kanagawa.nvim",
        config = function()
            require('kanagawa').setup({
                compile = false,  -- enable compiling the colorscheme
                undercurl = true, -- enable undercurls
                commentStyle = { italic = true },
                functionStyle = {},
                keywordStyle = { italic = false },
                statementStyle = { bold = true },
                typeStyle = {},
                transparent = true,    -- do not set background color
                dimInactive = false,   -- dim inactive window `:h hl-NormalNC`
                terminalColors = true, -- define vim.g.terminal_color_{0,17}
                colors = {             -- add/modify theme and palette colors
                    palette = {},
                    theme = {
                        wave = {},
                        dragon = {},
                        all = {
                            ui = {
                                bg_gutter = "none",
                                border = "rounded"
                            }
                        }
                    },
                },
                overrides = function(colors) -- add/modify highlights
                    local theme = colors.theme
                    return {
                        NormalFloat = { bg = "none" },
                        FloatBorder = { bg = "none" },
                        FloatTitle = { bg = "none" },
                        Pmenu = { fg = theme.ui.shade0, bg = "NONE", blend = vim.o.pumblend }, -- add `blend = vim.o.pumblend` to enable transparency
                        PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
                        PmenuSbar = { bg = theme.ui.bg_m1 },
                        PmenuThumb = { bg = theme.ui.bg_p2 },

                        -- Save an hlgroup with dark background and dimmed foreground
                        -- so that you can use it where your still want darker windows.
                        -- E.g.: autocmd TermOpen * setlocal winhighlight=Normal:NormalDark
                        NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },

                        -- Popular plugins that open floats will link to NormalFloat by default;
                        -- set their background accordingly if you wish to keep them dark and borderless
                        LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
                        MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
                        TelescopeTitle = { fg = theme.ui.special, bold = true },
                        TelescopePromptBorder = { fg = theme.ui.special, },
                        TelescopeResultsNormal = { fg = theme.ui.fg_dim, },
                        TelescopeResultsBorder = { fg = theme.ui.special, },
                        TelescopePreviewBorder = { fg = theme.ui.special },
                    }
                end,
                theme = "wave",    -- Load "wave" theme when 'background' option is not set
                background = {     -- map the value of 'background' option to a theme
                    dark = "wave", -- try "dragon" !
                },
            })
        end
    },
    -- NOTE: neosolarized 
    {
        "craftzdog/solarized-osaka.nvim",
        lazy = false,
        config = function()
            require("solarized-osaka").setup({
                transparent = true,
                terminal_colors = true, -- Configure the colors used when opening a `:terminal` in [Neovim](https://github.com/neovim/neovim)
                styles = {
                    -- Style to be applied to different syntax groups
                    -- Value is any valid attr-list value for `:help nvim_set_hl`
                    comments = { italic = true },
                    keywords = { italic = false },
                    functions = {},
                    variables = {},
                    -- Background styles. Can be "dark", "transparent" or "normal"
                    sidebars = "dark",            -- style for sidebars, see below
                    floats = "dark",              -- style for floating windows
                },
                sidebars = { "qf", "help" },      -- Set a darker background on sidebar-like windows. For example: `["qf", "vista_kind", "terminal", "packer"]`
                day_brightness = 0.3,             -- Adjusts the brightness of the colors of the **Day** style. Number between 0 and 1, from dull to vibrant colors
                hide_inactive_statusline = false, -- Enabling this option, will hide inactive statuslines and replace them with a thin border instead. Should work with the standard **StatusLine** and **LuaLine**.
                dim_inactive = false,             -- dims inactive windows
                lualine_bold = false,             -- When `true`, section headers in the lualine theme will be bold
                on_highlights = function(hl, c)
                    local prompt = "#2d3149"
                    hl.TelescopeNormal = {
                        bg = c.bg_dark,
                        fg = c.fg_dark,
                    }
                    hl.TelescopeBorder = {
                        bg = c.bg_dark,
                        fg = c.bg_dark,
                    }
                    hl.TelescopePromptNormal = {
                        bg = c.bg_dark,
                    }
                    hl.TelescopePromptBorder = {
                        bg = c.bg_dark,
                        fg = c.bg_dark,
                    }
                    hl.TelescopePromptTitle = {
                        bg = prompt,
                        fg = "#2C94DD",
                    }
                    hl.TelescopePreviewTitle = {
                        bg = c.bg_dark,
                        fg = c.bg_dark,
                    }
                    hl.TelescopeResultsTitle = {
                        bg = c.bg_dark,
                        fg = c.bg_dark,
                    }
                end,
            })
        end
    },
    -- NOTE: github
    {
        "projekt0n/github-nvim-theme",
        name = "github-theme",
        config = function()
            require("github-theme").setup({
                options = {
                    transparent = false,
                    hide_end_of_buffer = true,
                    hide_nc_statusline = true,
                    terminal_colors = true,
                    dim_inactive = false,
                    styles = {
                        comments = "NONE",
                        keywords = "NONE",
                    },
                    darken = {
                        floats = true,
                        sidebars = {
                            enable = true,
                            list = {},
                        },
                    },
                },
            })
        end,
    },
    -- NOTE : tokyonight
    {
        "folke/tokyonight.nvim",
        name = "folkeTokyonight",
        -- priority = 1000,
        config = function()
            local transparent = false
            local day_style = {
                bg = "#ffffff",
                bg_dark = "#f7f9fc",
                bg_float = "#f5f7fb",
                bg_highlight = "#e9eef7",
                bg_search = "#cfe8ff",
                bg_visual = "#dbeafe",
                fg = "#3760bf",
                fg_dark = "#6172b0",
                fg_gutter = "#99a7c2",
                border = "#cad3e6",
            }
            local dark_variants = {
                ["tokyonight-moon"] = true,
                ["tokyonight-night"] = true,
                ["tokyonight-storm"] = true,
            }
            local dark_selection = {
                bg = "#2f3b63",
                fg = "#c0caf5",
            }

            local function apply_tokyonight_transparency()
                if not dark_variants[vim.g.colors_name] then
                    return
                end

                local highlights = {
                    Normal = { bg = "none" },
                    NormalNC = { bg = "none" },
                    EndOfBuffer = { bg = "none" },
                    SignColumn = { bg = "none" },
                    NormalFloat = { bg = "none" },
                    FloatBorder = { bg = "none" },
                    FloatTitle = { bg = "none" },
                    Pmenu = { bg = "none" },
                    PmenuSel = { bg = dark_selection.bg, fg = dark_selection.fg, bold = true },
                    StatusLine = { bg = "none" },
                    StatusLineNC = { bg = "none" },
                    CursorLine = { bg = dark_selection.bg },
                    TelescopeNormal = { bg = "none" },
                    TelescopeBorder = { bg = "none" },
                    TelescopePromptNormal = { bg = "none" },
                    TelescopePromptBorder = { bg = "none" },
                    TelescopePromptTitle = { bg = "none" },
                    TelescopeResultsNormal = { bg = "none" },
                    TelescopeResultsBorder = { bg = "none" },
                    TelescopeSelection = { bg = dark_selection.bg, fg = dark_selection.fg, bold = true },
                    TelescopeResultsTitle = { bg = "none" },
                    TelescopePreviewNormal = { bg = "none" },
                    TelescopePreviewBorder = { bg = "none" },
                    TelescopePreviewTitle = { bg = "none" },
                    BlinkCmpMenu = { bg = "none" },
                    BlinkCmpMenuBorder = { bg = "none" },
                    BlinkCmpMenuSelection = { bg = dark_selection.bg, fg = dark_selection.fg, bold = true },
                    BlinkCmpDoc = { bg = "none" },
                    BlinkCmpDocBorder = { bg = "none" },
                }

                for group, opts in pairs(highlights) do
                    merge_highlight(group, opts)
                end
            end

            require("tokyonight").setup({
                style = "day",
                transparent = transparent,

                styles = {
                    comments = { italic = false },
                    keywords = { italic = false },
                    sidebars = "dark",
                    floats = "dark",
                },
                on_colors = function(colors)
                    if vim.g.colors_name ~= "tokyonight-day" and vim.g.colors_name ~= "tokyonight" then
                        return
                    end

                    colors.bg = day_style.bg
                    colors.bg_dark = day_style.bg_dark
                    colors.bg_float = day_style.bg_float
                    colors.bg_highlight = day_style.bg_highlight
                    colors.bg_popup = day_style.bg_float
                    colors.bg_search = day_style.bg_search
                    colors.bg_sidebar = day_style.bg_dark
                    colors.bg_statusline = day_style.bg_dark
                    colors.bg_visual = day_style.bg_visual
                    colors.border = day_style.border
                    colors.fg = day_style.fg
                    colors.fg_dark = day_style.fg_dark
                    colors.fg_float = day_style.fg
                    colors.fg_gutter = day_style.fg_gutter
                    colors.fg_sidebar = day_style.fg_dark
                end,
            })

            local group = vim.api.nvim_create_augroup("SethyTokyonightTransparency", { clear = true })

            vim.api.nvim_create_autocmd("ColorScheme", {
                group = group,
                pattern = "tokyonight*",
                callback = apply_tokyonight_transparency,
            })

            apply_tokyonight_transparency()
            -- vim.cmd("colorscheme tokyonight")
            -- NOTE: Auto switch to tokyonight for markdown files only
            -- vim.api.nvim_create_autocmd("FileType", {
            --     pattern = { "markdown" },
            --     callback = function()
            --         -- Ensure the theme switch only happens once for a buffer
            --         local buffer = vim.api.nvim_get_current_buf()
            --         if not vim.b[buffer].tokyonight_applied then
            --             if vim.fn.expand("%:t") ~= "" and vim.api.nvim_buf_get_option(0, "buftype") ~= "nofile" then
            --                 vim.cmd("colorscheme tokyonight")
            --             end
            --             vim.b[buffer].tokyonight_applied = true
            --         end
            --     end,
            -- })
        end,
    },
}
