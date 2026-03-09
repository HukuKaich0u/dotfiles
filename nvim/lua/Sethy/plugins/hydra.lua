return {
    {
        "anuvyklack/hydra.nvim",
        lazy = false,
        config = function()
            local Hydra = require("hydra")

            Hydra({
                name = "Resize split",
                mode = "n",
                body = "<leader>sz",
                config = {
                    color = "amaranth",
                    invoke_on_body = true,
                },
                hint = [[
     Resize split
    _h_: narrower   _l_: wider
    _j_: taller     _k_: shorter

    _<Enter>_/_<Esc>_: exit
                ]],
                heads = {
                    { "h", "<cmd>vertical resize -5<CR>", { desc = "narrower" } },
                    { "l", "<cmd>vertical resize +5<CR>", { desc = "wider" } },
                    { "j", "<cmd>resize +3<CR>", { desc = "taller" } },
                    { "k", "<cmd>resize -3<CR>", { desc = "shorter" } },
                    { "<Enter>", nil, { exit = true, desc = "exit" } },
                    { "<Esc>", nil, { exit = true, desc = false } },
                },
            })
        end,
    },
}
