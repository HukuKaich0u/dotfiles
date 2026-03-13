return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
        {
            "<leader>f",
            function()
                require("conform").format({ async = true, lsp_fallback = true })
            end,
            mode = "",
            desc = "Format buffer",
        },
    },
    opts = {
        formatters_by_ft = {
            -- lua
            lua = { "stylua" },
            -- web (biome: js/ts/json) - format + lint fix + import整理
            javascript = { "biome-check" },
            typescript = { "biome-check" },
            javascriptreact = { "biome-check" },
            typescriptreact = { "biome-check" },
            json = { "biome" },
            jsonc = { "biome" },
            -- web (prettier: html/css/yaml/markdown)
            html = { "prettier" },
            css = { "prettier" },
            scss = { "prettier" },
            yaml = { "prettier" },
            markdown = { "prettier" },
            -- fallback to LSP for: rust, python, c/cpp, java, zig, go
        },
        -- biome works with default settings even without biome.json
        -- format on save (optional, uncomment if you want)
        -- format_on_save = {
        --     timeout_ms = 500,
        --     lsp_fallback = true,
        -- },
    },
}
