return {
    "cordx56/rustowl",
    version = "*",
    lazy = false,
    build = "cargo binstall rustowl --no-confirm",
    -- RustOwl highlight legend:
    -- green(lifetime), blue(imm_borrow), purple(mut_borrow),
    -- yellow/orange(move/call), red(outlive error)
    keys = {
        {
            "<leader>lz",
            function()
                require("rustowl").toggle(0)
            end,
            ft = "rust",
            desc = "Toggle Rustowl",
            silent = true,
        },
    },
    opts = {
        auto_enable = true,
        idle_time = 200,
        highlight_style = "underline",
        client = {
            root_dir = function()
                local bufname = vim.api.nvim_buf_get_name(0)
                local root = vim.fs.root(bufname ~= "" and bufname or 0, { "Cargo.toml", ".git" })
                if root then
                    return root
                end
                return vim.uv.cwd()
            end,
        },
    },
}
