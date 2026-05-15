return {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false,
    init = function()
        vim.g.rustaceanvim = {
            server = {
                default_settings = {
                    ["rust-analyzer"] = {
                        checkOnSave = false,
                        cargo = {
                            allFeatures = true,
                        },
                    },
                },
            },
        }
    end,
}
