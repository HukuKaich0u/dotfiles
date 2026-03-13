return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local lualine = require("lualine")
        local lazy_status = require("lazy.status") -- to configure lazy pending updates count

        local colors = {
            bg = "NONE",
            bg_alt = "#1a1b26",
            blue = "#7aa2f7",
            cyan = "#7dcfff",
            gold = "#e0af68",
            red = "#f7768e",
            fg = "#c0caf5",
            fg_muted = "#7f85a3",
            purple = "#bb9af7",
        }

        local my_lualine_theme = {
            replace = {
                a = { fg = colors.bg_alt, bg = colors.red, gui = "bold" },
                b = { fg = colors.fg, bg = colors.bg },
            },
            inactive = {
                a = { fg = colors.fg_muted, bg = colors.bg, gui = "bold" },
                b = { fg = colors.fg_muted, bg = colors.bg },
                c = { fg = colors.fg_muted, bg = colors.bg },
            },
            normal = {
                a = { fg = colors.bg_alt, bg = colors.blue, gui = "bold" },
                b = { fg = colors.cyan, bg = colors.bg },
                c = { fg = colors.fg, bg = colors.bg },
            },
            visual = {
                a = { fg = colors.bg_alt, bg = colors.purple, gui = "bold" },
                b = { fg = colors.fg, bg = colors.bg },
            },
            insert = {
                a = { fg = colors.bg_alt, bg = colors.gold, gui = "bold" },
                b = { fg = colors.fg, bg = colors.bg },
            },
        }

        local mode = {
            'mode',
            fmt = function(str)
                -- return ''
                -- displays only the first character of the mode
                return ' ' .. str
            end,
        }

        local diff = {
            'diff',
            colored = true,
            symbols = { added = ' ', modified = ' ', removed = ' ' }, -- changes diff symbols
            -- cond = hide_in_width,
        }

        local filename = {
            'filename',
            file_status = true,
            path = 0,
        }

        local branch = {'branch', icon = {'', color = { fg = colors.cyan }}, '|'}

        lualine.setup({
            icons_enabled = true,
            options = {
                theme = my_lualine_theme,
                component_separators = { left = "|", right = "|" },
                section_separators = { left = "|", right = "" },
            },
            sections = {
                lualine_a = { mode },
                lualine_b = { branch },
                lualine_c = { diff, filename },
                lualine_x = {
                    {
                        -- require("noice").api.statusline.mode.get,
                        -- cond = require("noice").api.statusline.mode.has,
                        lazy_status.updates,
                        cond = lazy_status.has_updates,
                        color = { fg = colors.gold },
                    },
                    -- { "encoding" },
                    -- { "fileformat" },
                    { "filetype" },
                },
            },
        })

    end
}
