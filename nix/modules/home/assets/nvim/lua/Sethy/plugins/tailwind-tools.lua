return {
    {
        "NvChad/nvim-colorizer.lua",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
        opts = {},
        config = function()
            local nvchadcolorizer = require("colorizer")

            nvchadcolorizer.setup({
                user_default_options = {
                    tailwind = true,
                },
                filetypes = {
                    "html",
                    "css",
                    "javascript",
                    "typescript",
                    "javascriptreact",
                    "typescriptreact",
                    "vue",
                    "svelte",
                    "astro",
                },
            })
        end
    }
}
