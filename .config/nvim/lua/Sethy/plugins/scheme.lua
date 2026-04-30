return {
    {
        "Olical/conjure",
        ft = { "racket", "scheme", "lisp" },
        init = function()
            vim.g["conjure#mapping#doc_word"] = false
            vim.g["conjure#extract#tree_sitter#enabled"] = true
        end,
    },
    {
        "HiPhish/rainbow-delimiters.nvim",
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
        ft = { "racket", "scheme", "lisp" },
        init = function()
            vim.g.rainbow_delimiters = {
                highlight = {
                    "RainbowDelimiterRed",
                    "RainbowDelimiterYellow",
                    "RainbowDelimiterBlue",
                    "RainbowDelimiterOrange",
                    "RainbowDelimiterGreen",
                    "RainbowDelimiterViolet",
                    "RainbowDelimiterCyan",
                },
            }
        end,
    },
}
