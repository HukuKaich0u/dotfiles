return {
    "mrcjkb/rustaceanvim",
    version = "^9",
    lazy = false,
    dependencies = { "saghen/blink.cmp" },
    init = function()
        -- Resolve after plugins are available, preserving rustaceanvim's extensions.
        vim.g.rustaceanvim = function()
            return {
                server = {
                    capabilities = require("blink.cmp").get_lsp_capabilities(
                        require("rustaceanvim.config.server").create_client_capabilities()
                    ),
                    default_settings = {
                        ["rust-analyzer"] = {
                            checkOnSave = true,
                            -- Use Cargo's default features; allFeatures can enable
                            -- mutually exclusive backends. Override per project.
                            cargo = { allFeatures = false },
                        },
                    },
                },
            }
        end
    end,
    keys = {
        { "<leader>lr", "<cmd>RustLsp runnables<CR>", ft = "rust", desc = "Rust runnables" },
        { "<leader>lt", "<cmd>RustLsp testables<CR>", ft = "rust", desc = "Rust tests" },
        { "<leader>lm", "<cmd>RustLsp expandMacro<CR>", ft = "rust", desc = "Expand Rust macro" },
    },
}
