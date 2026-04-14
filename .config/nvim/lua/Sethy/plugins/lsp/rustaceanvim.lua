return {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false,
    init = function()
        vim.g.rustaceanvim = {
            server = {
                default_settings = {
                    ["rust-analyzer"] = {
                        checkOnSave = true,
                        check = {
                            command = "clippy",
                        },
                        cargo = {
                            allFeatures = true,
                        },
                    },
                },
            },
        }
    end,
}
