return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local ts = require("nvim-treesitter")

            -- Install parsers on startup
            local parsers = {
                -- data / config
                "json", "yaml", "toml", "ini",

                -- web
                "javascript", "typescript", "tsx",
                "html", "css",

                -- backend / systems
                "python", "go", "java",
                "rust", "zig", "c", "cpp",

                -- infra
                "dockerfile", "terraform", "http",

                -- db
                "sql", "prisma",

                -- docs
                "markdown", "markdown_inline",

                -- tooling
                "bash", "lua", "vim", "vimdoc",
                "gitignore", "query", "regex",
                "make", "diff", "tmux",
            }

            ts.install(parsers, { summary = false }):wait(30000)

            -- Enable treesitter features for all filetypes
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("treesitter_enable", { clear = true }),
                pattern = "*",
                callback = function(event)
                    -- Enable highlighting
                    pcall(vim.treesitter.start, event.buf)

                    -- Enable indentation
                    vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })
        end,
    },
    -- NOTE: js, ts, jsx, tsx Auto Close Tags
    {
        "windwp/nvim-ts-autotag",
        ft = { "html", "xml", "javascript", "typescript", "javascriptreact", "typescriptreact", "svelte" },
        config = function()
            require("nvim-ts-autotag").setup({
                opts = {
                    enable_close = true,
                    enable_rename = true,
                    enable_close_on_slash = false,
                },
            })
        end,
    },
}
