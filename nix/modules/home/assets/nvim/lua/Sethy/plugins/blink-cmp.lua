return {
    "saghen/blink.cmp",
    version = "1.*",
    dependencies = {
        {
            "L3MON4D3/LuaSnip",
            version = "v2.*",
        },
        "rafamadriz/friendly-snippets",
    },
    init = function()
        local set_hl = vim.api.nvim_set_hl

        set_hl(0, "BlinkCmpMenu", { link = "Pmenu" })
        set_hl(0, "BlinkCmpMenuBorder", { fg = "#7C8AA6", bg = "NONE" })
        set_hl(0, "BlinkCmpMenuSelection", { link = "PmenuSel" })
        set_hl(0, "BlinkCmpDoc", { link = "NormalFloat" })
        set_hl(0, "BlinkCmpDocBorder", { fg = "#7C8AA6", bg = "NONE" })
        set_hl(0, "BlinkCmpSource", { fg = "#6B7280", italic = true })

        set_hl(0, "BlinkCmpKind", { fg = "#C0CAF5" })
        set_hl(0, "BlinkCmpKindFunction", { fg = "#61AFEF" })
        set_hl(0, "BlinkCmpKindMethod", { fg = "#61AFEF" })
        set_hl(0, "BlinkCmpKindVariable", { fg = "#E06C75" })
        set_hl(0, "BlinkCmpKindField", { fg = "#E06C75" })
        set_hl(0, "BlinkCmpKindProperty", { fg = "#E06C75" })
        set_hl(0, "BlinkCmpKindClass", { fg = "#E5C07B" })
        set_hl(0, "BlinkCmpKindStruct", { fg = "#E5C07B" })
        set_hl(0, "BlinkCmpKindInterface", { fg = "#E5C07B" })
        set_hl(0, "BlinkCmpKindModule", { fg = "#C678DD" })
        set_hl(0, "BlinkCmpKindKeyword", { fg = "#F7768E" })
        set_hl(0, "BlinkCmpKindSnippet", { fg = "#98C379" })
        set_hl(0, "BlinkCmpKindText", { fg = "#ABB2BF" })
    end,
    opts_extend = { "sources.default" },
    opts = {
        keymap = {
            preset = "default",
            ["<C-n>"] = { "select_next", "fallback" },
            ["<C-p>"] = { "select_prev", "fallback" },
            ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
            ["<C-d>"] = { "hide_documentation", "fallback" },
            ["<CR>"] = { "accept", "fallback" },
            ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
            ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
        },
        appearance = {
            use_nvim_cmp_as_default = false,
            nerd_font_variant = "mono",
        },
        snippets = {
            preset = "luasnip",
        },
        signature = { enabled = true, window = { border = "rounded" } },
        completion = {
            list = {
                selection = {
                    preselect = false,
                    auto_insert = false,
                },
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 200,
                window = {
                    border = "rounded",
                    winhighlight = "Normal:BlinkCmpDoc,FloatBorder:BlinkCmpDocBorder,EndOfBuffer:BlinkCmpDoc",
                },
            },
            menu = {
                border = "rounded",
                winhighlight = "Normal:BlinkCmpMenu,FloatBorder:BlinkCmpMenuBorder,CursorLine:BlinkCmpMenuSelection,Search:None",
                draw = {
                    components = {
                        kind_icon = {
                            highlight = function(ctx)
                                return ctx.kind_hl
                            end,
                        },
                        kind = {
                            highlight = function(ctx)
                                return ctx.kind_hl
                            end,
                        },
                        source_name = {
                            highlight = "BlinkCmpSource",
                        },
                    },
                    columns = {
                        { "kind_icon" },
                        { "kind", gap = 1 },
                        { "label", "label_description", gap = 1 },
                        { "source_name" },
                    },
                },
            },
            ghost_text = {
                enabled = true,
                show_with_selection = true,
            },
        },
        cmdline = {
            keymap = {
                preset = "cmdline",
            },
            completion = {
                menu = {
                    auto_show = false,
                },
                ghost_text = {
                    enabled = false,
                },
            },
        },
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },
            providers = {
                lsp = {
                    name = "[LSP]",
                },
                path = {
                    name = "[Path]",
                },
                snippets = {
                    name = "[Snip]",
                },
                buffer = {
                    name = "[Buffer]",
                },
            },
        },
        fuzzy = {
            implementation = "prefer_rust_with_warning",
        },
    },
    config = function(_, opts)
        require("luasnip.loaders.from_vscode").lazy_load()
        require("blink.cmp").setup(opts)
    end,
}
