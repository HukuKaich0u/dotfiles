return {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local lualine = require("lualine")
        local lazy_status = require("lazy.status") -- to configure lazy pending updates count

        -- 自前テーマ (colors/sethy-*.lua) 以外で使う色。tokyonight の値
        local tokyonight = {
            mode_fg = "#1a1b26",
            normal = "#7aa2f7",
            insert = "#e0af68",
            visual = "#bb9af7",
            replace = "#f7768e",
            fg = "#c0caf5",
            fg_muted = "#7f85a3",
            branch = "#7dcfff",
            updates = "#e0af68",
        }

        -- 自前テーマのときは、そのテーマがコードに使っている色からモード表示などを作る。
        -- 背景は透過のまま (NONE) にする
        local function current_colors()
            local p = require("Sethy.colors.ui").palette()
            if not p then
                return tokyonight
            end
            return {
                mode_fg = p.mode_fg,
                normal = p.mode_normal,
                insert = p.mode_insert,
                visual = p.mode_visual,
                replace = p.mode_replace,
                command = p.mode_command,
                fg = p.fg,
                fg_muted = p.fg_muted,
                branch = p.accent_alt,
                updates = p.mode_command,
            }
        end

        local function build_theme(c)
            local function mode_section(bg)
                return {
                    a = { fg = c.mode_fg, bg = bg, gui = "bold" },
                    b = { fg = c.fg, bg = "NONE" },
                }
            end
            local theme = {
                normal = {
                    a = { fg = c.mode_fg, bg = c.normal, gui = "bold" },
                    b = { fg = c.branch, bg = "NONE" },
                    c = { fg = c.fg, bg = "NONE" },
                },
                insert = mode_section(c.insert),
                visual = mode_section(c.visual),
                replace = mode_section(c.replace),
                inactive = {
                    a = { fg = c.fg_muted, bg = "NONE", gui = "bold" },
                    b = { fg = c.fg_muted, bg = "NONE" },
                    c = { fg = c.fg_muted, bg = "NONE" },
                },
            }
            -- command がないテーマでは lualine が normal の色を使う
            if c.command then
                theme.command = mode_section(c.command)
            end
            return theme
        end

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

        local function build_config(c)
            local branch = { 'branch', icon = { '', color = { fg = c.branch } }, '|' }
            return {
                icons_enabled = true,
                options = {
                    theme = build_theme(c),
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
                            color = { fg = c.updates },
                        },
                        -- { "encoding" },
                        -- { "fileformat" },
                        { "filetype" },
                    },
                },
            }
        end

        lualine.setup(build_config(current_colors()))

        -- テーマを切り替えたら、そのテーマの色で作り直す
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("SethyLualineTheme", { clear = true }),
            callback = function()
                lualine.setup(build_config(current_colors()))
            end,
        })

    end
}
