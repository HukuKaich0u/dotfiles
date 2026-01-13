return {
    -- Mini Nvim
    { "echasnovski/mini.nvim", version = false },

    -- File explorer (this works properly with oil unlike nvim-tree)
    {
        "echasnovski/mini.files",
        config = function()
            local MiniFiles = require("mini.files")
            MiniFiles.setup({
                mappings = {
                    go_in = "<CR>", -- Map both Enter and L to Enter directories or open files
                    go_in_plus = "L",
                    go_out = "-",
                    go_out_plus = "H",
                },
            })
            vim.keymap.set("n", "<leader>ee", "<cmd>lua MiniFiles.open()<CR>", { desc = "Toggle mini file explorer" }) -- toggle file explorer
            vim.keymap.set("n", "<leader>ef", function()
                MiniFiles.open(vim.api.nvim_buf_get_name(0), false)
                MifiFiles.reveal_cwd()
            end, { desc = "Toggle into currently opend file" })
        end
    }
}

