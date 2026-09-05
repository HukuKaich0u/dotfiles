local function web_formatters(bufnr)
    local conform = require("conform")
    local prettier = conform.get_formatter_info("prettier", bufnr)
    local biome = conform.get_formatter_info("biome", bufnr)
    -- The nearest explicit config wins. At the same root, Prettier can own
    -- formatting while Biome provides lint. Unconfigured projects use Prettier.
    if biome.cwd and (not prettier.cwd or #biome.cwd > #prettier.cwd) then
        return { "biome" }
    end
    return { "prettier" }
end

return {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo", "FormatToggle" },
    keys = {
        {
            "<leader>f",
            function()
                require("conform").format({ async = true })
            end,
            mode = { "n", "x" },
            desc = "Format buffer or selection",
        },
        {
            "<leader>cf",
            function()
                require("conform").format({ async = true })
            end,
            mode = { "n", "x" },
            desc = "Format buffer or selection",
        },
    },
    opts = {
        default_format_opts = { timeout_ms = 3000, lsp_format = "never" },
        formatters_by_ft = {
            lua = { "stylua" },
            javascript = web_formatters,
            typescript = web_formatters,
            javascriptreact = web_formatters,
            typescriptreact = web_formatters,
            json = web_formatters,
            jsonc = web_formatters,
            html = { "prettier" },
            css = { "prettier" },
            scss = { "prettier" },
            yaml = { "prettier" },
            markdown = { "prettier" },
            go = { "goimports", "gofumpt" },
            python = { "ruff_format" },
            -- rust-analyzer knows the crate's edition and rustup toolchain.
            rust = { lsp_format = "fallback" },
            java = { lsp_format = "fallback" },
            c = { "clang_format" },
            cpp = { "clang_format" },
            objc = { "clang_format" },
            objcpp = { "clang_format" },
            nix = { "alejandra" },
            sh = { "shfmt" },
            bash = { "shfmt" },
            -- shfmt does not support zsh syntax.
        },
        formatters = {
            biome = {
                require_cwd = true,
                -- Equal priority prevents an ancestor biome.json from winning
                -- over a nearer biome.jsonc on Neovim 0.12.
                cwd = function(_, ctx)
                    return vim.fs.root(ctx.dirname, { { "biome.json", "biome.jsonc" } })
                end,
            },
        },
        format_on_save = function(bufnr)
            if
                vim.g.disable_autoformat
                or vim.b[bufnr].disable_autoformat
                or vim.bo[bufnr].buftype ~= ""
                or not vim.bo[bufnr].modifiable
            then
                return
            end
            local filetypes = {
                rust = true,
                go = true,
                python = true,
                java = true,
                c = true,
                cpp = true,
                javascript = true,
                typescript = true,
                javascriptreact = true,
                typescriptreact = true,
                html = true,
                css = true,
                scss = true,
                lua = true,
                nix = true,
                sh = true,
                bash = true,
            }
            if filetypes[vim.bo[bufnr].filetype] then
                return { timeout_ms = 2000 }
            end
        end,
    },
    config = function(_, opts)
        require("conform").setup(opts)
        vim.api.nvim_create_user_command("FormatToggle", function(args)
            local scope = args.bang and vim.g or vim.b
            scope.disable_autoformat = not scope.disable_autoformat
            vim.notify(
                ("Autoformat %s (%s)"):format(
                    scope.disable_autoformat and "disabled" or "enabled",
                    args.bang and "global" or "buffer"
                )
            )
        end, { bang = true, desc = "Toggle format on save for this buffer (!: global)" })
    end,
}
