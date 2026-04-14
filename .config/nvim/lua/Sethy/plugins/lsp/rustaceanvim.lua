return {
    "mrcjkb/rustaceanvim",
    version = "^6",
    lazy = false,
    init = function()
        vim.api.nvim_create_autocmd("FileType", {
            pattern = "rust",
            callback = function(args)
                vim.keymap.set("n", "<leader>lb", function()
                    if vim.fn.executable("bacon") == 0 then
                        vim.notify("bacon is not installed", vim.log.levels.ERROR)
                        return
                    end

                    local root = vim.fs.root(args.buf, { "Cargo.toml", ".git" }) or vim.uv.cwd()
                    Snacks.terminal("bacon", {
                        cwd = root,
                        win = {
                            position = "bottom",
                            height = 0.4,
                        },
                    })
                end, {
                    buffer = args.buf,
                    desc = "Toggle bacon",
                    silent = true,
                })
            end,
        })

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
