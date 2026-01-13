return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",
        config = function()
            local ts = require("nvim-treesitter")

            -- Install parsers on startup
            ts.install({
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
                "make", "diff", "tmux"
            }, { summary = false }):wait(30000)

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

            -- Incremental selection keymaps
            vim.keymap.set("n", "<C-space>", function()
                vim.cmd("normal! v")
                require("nvim-treesitter.incremental_selection").init_selection()
            end, { desc = "Init incremental selection" })

            vim.keymap.set("x", "<C-space>", function()
                require("nvim-treesitter.incremental_selection").node_incremental()
            end, { desc = "Increment node selection" })
        end
    }
}
