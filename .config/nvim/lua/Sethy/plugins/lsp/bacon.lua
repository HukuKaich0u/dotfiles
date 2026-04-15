local function project_root(bufnr)
    return vim.fs.root(bufnr, { "Cargo.toml", ".git" }) or vim.uv.cwd()
end

local function open_bacon_terminal()
    if vim.fn.executable("bacon") == 0 then
        vim.notify("bacon is not installed", vim.log.levels.ERROR)
        return
    end

    Snacks.terminal("bacon", {
        cwd = project_root(0),
        win = {
            position = "bottom",
            height = 0.4,
        },
    })
end

return {
    {
        "Canop/nvim-bacon",
        ft = "rust",
        init = function()
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "bacon",
                callback = function(args)
                    vim.keymap.set("n", "<C-j>", "j", {
                        buffer = args.buf,
                        noremap = true,
                        silent = true,
                        desc = "Move down in bacon locations",
                    })
                    vim.keymap.set("n", "<C-k>", "k", {
                        buffer = args.buf,
                        noremap = true,
                        silent = true,
                        desc = "Move up in bacon locations",
                    })
                end,
            })
        end,
        opts = {
            quickfix = {
                enabled = true,
                event_trigger = true,
            },
        },
        keys = {
            {
                "<leader>lB",
                "<cmd>BaconList<CR>",
                ft = "rust",
                desc = "Open bacon locations",
                silent = true,
            },
            {
                "<leader>lj",
                "<cmd>BaconNext<CR>",
                ft = "rust",
                desc = "Next bacon location",
                silent = true,
            },
            {
                "<leader>lk",
                "<cmd>BaconPrevious<CR>",
                ft = "rust",
                desc = "Previous bacon location",
                silent = true,
            },
        },
    },
    {
        "mrcjkb/rustaceanvim",
        keys = {
            {
                "<leader>lb",
                open_bacon_terminal,
                ft = "rust",
                desc = "Toggle bacon",
                silent = true,
            },
        },
    },
}
