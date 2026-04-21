return {
    "Saghen/blink.cmp",
    version = "1.*",
    dependencies = {
        {
            "L3MON4D3/LuaSnip",
            version = "v2.*",
        },
        "rafamadriz/friendly-snippets",
    },
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
            nerd_font_variant = "mono",
        },
        snippets = {
            preset = "luasnip",
        },
        completion = {
            list = {
                selection = {
                    preselect = false,
                    auto_insert = false,
                },
            },
            documentation = {
                auto_show = false,
            },
            menu = {
                draw = {
                    columns = {
                        { "label", "label_description", gap = 1 },
                        { "kind_icon", "kind" },
                    },
                },
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
        },
        fuzzy = {
            implementation = "prefer_rust_with_warning",
        },
    },
}
