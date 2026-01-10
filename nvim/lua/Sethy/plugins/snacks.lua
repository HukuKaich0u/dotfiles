return {
    {
        "folke/snacks.nvim",
        priority = 1000,
        lazy = false,
        opts = {
            -- HACK: docs @ https://github.com/folke/snacks.nvim/blob/main/docs
            explorer = {
                enabed = true,
                layout = {
                    cycle = false,
                },
            },
        },
    },
    {
        keys = {
            { "<leader>lg", function() require("snacks").lazygit() end, desc = "lazygit" },
            { "<leader>gl", function() require("snacks").lazygit.log() end, desc = "lazygit logs" },
            { "<leader>es", function() require("snacks").explorer() end, desc = "open snacks explorer" },
            { "<leader>rn", function() require("snacks").rename.rename_file() end, desc = "fast rename current file" },
            { "<leader>db", function() require("snacks").bufdelete() end, desc = "delete or close buffer (confirm)" },


            -- snacks picker
            { "<leader>pf", function() require("snacks").picker.files() end, desc = "find files (snacks picker)" },
            { "<leader>pc", function() require("snacks").picker.files({ cwd = vim.fn.stdpath("config") }) end, desc = "find config file" },
            { "<leader>ps", function() require("snacks").picker.grep() end, desc = "grep word" },
            { "<leader>pws", function() require("snacks").picker.grep_word() end, desc = "search visual selection or word", mode = { "n", "x" } },
            { "<leader>pk", function() require("snacks").picker.keymaps({layout = "ivy" }) end, desc = "search keymaps (snacks picker)" },
            
            { "<leader>gbr", function() require("snacks").picker.git_branches({ layout = "select" }) end, desc = "pick and switch git branches" },
            { "<leader>th", function() require("snacks").picker.colorschemes({ layout = "ivy" }) end, desc = "pick color schemes" },
            { "<leader>vh", function() require("snacks").picker.help() end, desc = "help pages" },
        },
    },
}
