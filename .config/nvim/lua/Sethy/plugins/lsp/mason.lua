return {
    "williamboman/mason.nvim",
    lazy = false,
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
        "hrsh7th/cmp-nvim-lsp",
        "neovim/nvim-lspconfig",
        -- "saghen/blink.cmp",
    },
    config = function()
        -- import mason and mason_lspconfig
        local mason = require("mason")
        local mason_lspconfig = require("mason-lspconfig")
        local mason_tool_installer = require("mason-tool-installer")

        -- NOTE: Moved these local imports below back to lspconfig.lua due to mason depracated handlers

        -- local lspconfig = require("lspconfig")
        -- local cmp_nvim_lsp = require("cmp_nvim_lsp")             -- import cmp-nvim-lsp plugin
        -- local capabilities = cmp_nvim_lsp.default_capabilities() -- used to enable autocompletion (assign to every lsp server config)

        -- enable mason and configure icons
        mason.setup({
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        })

        mason_lspconfig.setup({
            automatic_enable = false,
            -- servers for mason to install
            ensure_installed = {
                -- lua
                "lua_ls",
                -- web
                "ts_ls",
                "html",
                "cssls",
                "tailwindcss",
                "astro",
                "emmet_ls",
                "emmet_language_server",
                "eslint",
                -- backend / systems
                "gopls",        -- Go
                "pyright",      -- Python (type checking)
                "ruff",         -- Python (linter/formatter)
                "rust_analyzer", -- Rust
                "clangd",       -- C/C++
                "jdtls",        -- Java
                "zls",          -- Zig
            },
        })

        mason_tool_installer.setup({
            ensure_installed = {
                -- formatters
                "biome",      -- js/ts/json (fast, rust-based)
                "prettier",   -- html/css/yaml/markdown
                "stylua",     -- lua
                "gofumpt",    -- go
                -- note: ruff replaces black/isort/pylint for python
                -- note: rustfmt usually comes with rust toolchain
            },

            -- NOTE: mason BREAKING Change! Removed setup_handlers
            -- moved lsp configuration settings back into lspconfig.lua file
        })
    end,
}
