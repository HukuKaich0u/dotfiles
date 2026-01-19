return {
    -- Mini Nvim (disabled for crash test)
    -- { "echasnovski/mini.nvim", version = false },
    -- Comments
    {
        "echasnovski/mini.comment",
        version = false,
        dependencies = {
            "JoosepAlviste/nvim-ts-context-commentstring",
        },
        config = function()
            -- disable the autocommand from ts-context-commentstring
            require("ts_context_commentstring").setup {
                enable_autcmd = false,
            }
            require("mini.comment").setup {
                -- tsx, jsx, html, svelte comment support
                options = {
                    custom_commentstring = function()
                        return require("ts_context_commentstring.internal").calculate_commentstring({ key = "commentstring" }) or vim.bo.commentstring
                    end,
                },
            }
        end
    },

    -- File explorer (using snacks.explorer instead)
    {
        "echasnovski/mini.files",
        enabled = false,
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
                MiniFiles.reveal_cwd()
            end, { desc = "Toggle into currently opend file" })
        end
    },
    {
        "echasnovski/mini.surround",
        enabled = true,
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            -- Add custom surroundings to be used on top of builin ones.
            -- For more information with examples, see `:h MiniSurround.config`.
            custom_surroundings = nil,

            -- Duration (in ms) of highlight when calling `MiniSurround.highlight()`
            highlight_duration = 300,

            -- Module mappings. Use `''` (empty string) to disable one.
            -- INFO:
            -- loose ver: sawi[ surround with whitespace
            -- tightver: sawi] surround with no whitespace
            mappings = {
                add = 'sa',            -- Add surrounding in Normal and Visual modes
                delete = 'ds',         -- Delete surrounding
                find = 'sf',           -- Find surrounding (to the right)
                find_left = 'sF',      -- Find surrounding (to the left)
                highlight = 'sh',      -- Highlight surrounding
                replace = 'sr',        -- Replace surrounding
                update_n_lines = 'sn', -- Update `n_lines`

                suffix_last = 'l',     -- Suffix to search with "prev" method
                suffix_next = 'n',     -- Suffix to search whth "next" method
            },

            -- Number of lines within which surrounding is searched
            n_lines = 20,

            -- Whether to respect selection typs:
            --  - Place surroundings on separate lines in linewise mode.
            --  - Place surroundings on each line in blockwise mode.
            respect_selection_type = false,

            -- How to search for surrounding (first inside current line, then inside
            -- neighborhood). One of 'cover', 'cover_or_next', 'cover_or_prev',
            -- 'cover_or_nearest', 'next', 'prev', 'nearest'. For more details,
            -- see `:h MiniSurround.config`.
            search_method = 'cover',

            -- Whether to disable showing non-error feedback
            silent = false,
        }
    },
    -- get rid of whitespace (disabled for crash test)
    -- {
    --     "echasnovski/mini.trailspace",
    --     event = { "BufReadPost", "BufNewFile" },
    --     config = function()
    --         local minitrailspace = require("mini.trailspace")
    --
    --         minitrailspace.setup({
    --             only_in_normal_buffers = true,
    --         })
    --
    --         vim.keymap.set("n", "<leader>cw", function() minitrailspace.trim() end, { desc = "erase whitespace" })
    --
    --         -- Ensure highlight never reappears by removing it on CursorMoved
    --         vim.api.nvim_create_autocmd("CursorMoved", {
    --             pattern = "*",
    --             callback = function()
    --                 require("mini.trailspace").unhighlight()
    --             end,
    --         })
    --     end
    -- },
    {
        "echasnovski/mini.splitjoin",
        enabled = true,
        config = function()
            local miniSplitJoin = require("mini.splitjoin")

            miniSplitJoin.setup({
                mappings = { toggle = "" }, -- Disable default mapping
            })

            vim.keymap.set({"n", "x"}, "sj", function() miniSplitJoin.join() end, { desc = "join arguments" })
            vim.keymap.set({ "n", "x" }, "sk", function() miniSplitJoin.split() end, { desc = "split arguments" })

        end
    }  
}

