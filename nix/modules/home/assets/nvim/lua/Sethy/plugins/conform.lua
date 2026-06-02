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
            astro = { "prettier" },
            svelte = { "prettier" },
            yaml = { "prettier" },
            markdown = { "prettier" },
            -- backend / systems
            c = { "clang_format" },
            cpp = { "clang_format" },
            objc = { "clang_format" },
            objcpp = { "clang_format" },
            nix = { "alejandra" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            zsh = { "shfmt" },
            -- fallback to LSP for: rust, python, java, zig, go
        },
        -- biome works with default settings even without biome.json
        format_on_save = function(bufnr)
            local format_on_save_filetypes = {
                html = true,
                css = true,
                scss = true,
                javascript = true,
                typescript = true,
                javascriptreact = true,
                typescriptreact = true,
                astro = true,
                svelte = true,
                nix = true,
                java = true,
                sh = true,
                bash = true,
                zsh = true,
            }

            if format_on_save_filetypes[vim.bo[bufnr].filetype] then
                return {
                    timeout_ms = 500,
                    lsp_fallback = true,
                }
            end
        end,
    },
}
