return {
    "mason-org/mason.nvim",
    lazy = false,
    dependencies = {
        "mason-org/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "neovim/nvim-lspconfig",
    },
    config = function()
        -- Nix provides these on both platforms; don't shadow them with Mason copies.
        local native_servers = { lua_ls = "lua-language-server", clangd = "clangd" }
        local servers = { "jdtls" }
        for name in pairs(require("Sethy.core.servers")) do
            if not native_servers[name] or vim.fn.executable(native_servers[name]) == 0 then
                table.insert(servers, name)
            end
        end
        table.sort(servers)

        require("mason").setup({
            -- Preserve project toolchains (mise, rustup, Nix); Mason supplies fallbacks.
            PATH = "append",
            ui = { icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" } },
        })
        require("mason-lspconfig").setup({
            automatic_enable = false,
            ensure_installed = servers,
        })
        require("mason-tool-installer").setup({
            ensure_installed = {
                "prettier",
                "stylua",
                "goimports",
                "gofumpt",
                {
                    "clang-format",
                    condition = function()
                        return vim.fn.executable("clang-format") == 0
                    end,
                },
                "alejandra",
                "shfmt",
                "shellcheck",
                -- Biome and Ruff are installed with their LSPs above.
                -- rust-analyzer, rustfmt and clippy belong to the rustup toolchain.
            },
        })
    end,
}
