return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        { "antosha417/nvim-lsp-file-operations", config = true },
        "mfussenegger/nvim-dap",
        "MunifTanjim/nui.nvim",
        "Saghen/blink.cmp",
    },
    config = function()
        local capabilities = require("blink.cmp").get_lsp_capabilities()

        -- NOTE: LSP Keybinds
        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", {}),
            callback = function(ev)
                local client = vim.lsp.get_client_by_id(ev.data.client_id)
                if not client then
                    return
                end

                -- Buffer local mappings
                local opts = { buffer = ev.buf, silent = true }

                -- Keymaps
                opts.desc = "Show LSP references"
                vim.keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

                opts.desc = "Go to declaration"
                vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

                opts.desc = "Show LSP definitions"
                vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

                opts.desc = "Show LSP implementations"
                vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

                opts.desc = "Show LSP type definitions"
                vim.keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

                opts.desc = "See available code actions"
                vim.keymap.set({ "n", "v" }, "<leader>vca", function()
                    vim.lsp.buf.code_action()
                end, opts)

                opts.desc = "Smart rename"
                vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

                opts.desc = "Show buffer diagnostics"
                vim.keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

                opts.desc = "Show line diagnostics"
                vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

                opts.desc = "Show documentation for what is under cursor"
                vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)

                opts.desc = "Restart LSP"
                vim.keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)

                vim.keymap.set("i", "<C-h>", function()
                    vim.lsp.buf.signature_help()
                end, opts)

            end,
        })

        -- Define sign icons for each severity
        local signs = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = "󰠠 ",
            [vim.diagnostic.severity.INFO] = " ",
        }

        -- Set diagnostic config
        vim.diagnostic.config({
            signs = {
                text = signs,
            },
            virtual_text = true,
            underline = true,
            update_in_insert = false,
        })

        -- Configure and enable LSP servers
        -- lua_ls
        vim.lsp.config("lua_ls", {
            capabilities = capabilities,
            settings = {
                Lua = {
                    diagnostics = {
                        globals = { "vim" },
                    },
                    completion = {
                        callSnippet = "Replace",
                    },
                    workspace = {
                        library = {
                            [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                            [vim.fn.stdpath("config") .. "/lua"] = true,
                        },
                    },
                },
            },
        })

        -- emmet_language_server
        vim.lsp.config("emmet_language_server", {
            capabilities = capabilities,
            filetypes = {
                "css",
                "html",
                "less",
                "sass",
                "scss",
                "javascriptreact",
                "astro",
                "svelte",
                "typescriptreact",
            },
            init_options = {
                includeLanguages = {},
                excludeLanguages = {},
                extensionsPath = {},
                preferences = {},
                showAbbreviationSuggestions = true,
                showExpandedAbbreviation = "always",
                showSuggestionsAsSnippets = false,
                syntaxProfiles = {},
                variables = {},
            },
        })

        -- ts_ls (TypeScript/JavaScript)
        vim.lsp.config("ts_ls", {
            capabilities = capabilities,
            filetypes = {
                "javascript",
                "javascriptreact",
                "typescript",
                "typescriptreact",
            },
            single_file_support = true,
            init_options = {
                preferences = {
                    includeCompletionsForModuleExports = true,
                    includeCompletionsForImportStatements = true,
                },
            },
        })

        -- gopls
        vim.lsp.config("gopls", {
            capabilities = capabilities,
            settings = {
                gopls = {
                    analyses = {
                        unusedparams = true,
                    },
                    staticcheck = true,
                    gofumpt = true,
                },
            },
        })

        -- tailwind
        vim.lsp.config("tailwindcss", {
            capabilities = capabilities,
            filetypes = {
                "html",
                "css",
                "javascript",
                "typescript",
                "javascriptreact",
                "typescriptreact",
                "svelte",
                "vue",
                "astro",
            },
            init_options = {
                userLanguages = {
                    astro = "html",
                },
            },
        })

        -- pyright (Python - type checking)
        vim.lsp.config("pyright", {
            capabilities = capabilities,
            settings = {
                python = {
                    analysis = {
                        typeCheckingMode = "basic",
                        autoSearchPaths = true,
                        useLibraryCodeForTypes = true,
                    },
                },
            },
        })

        -- ruff (Python - linter/formatter)
        vim.lsp.config("ruff", {
            capabilities = capabilities,
        })

        -- clangd (C/C++)
        vim.lsp.config("clangd", {
            capabilities = capabilities,
            cmd = {
                "clangd",
                "--background-index",
                "--clang-tidy",
                "--header-insertion=iwyu",
                "--completion-style=detailed",
            },
        })

        vim.lsp.config("html", {
            capabilities = capabilities,
            filetypes = {
                "html",
                "templ",
            },
            init_options = {
                provideFormatter = false,
            },
        })

        vim.lsp.config("cssls", {
            capabilities = capabilities,
            filetypes = {
                "css",
                "scss",
                "less",
                "sass",
            },
        })

        vim.lsp.config("astro", {
            capabilities = capabilities,
        })

        vim.lsp.config("svelte", {
            capabilities = capabilities,
        })

        vim.lsp.config("typos_lsp", {
            capabilities = capabilities,
            cmd = { "typos-lsp" },
            init_options = {
                config = vim.fn.stdpath("config") .. "/typos.toml",
            },
        })

        -- zls (Zig)
        vim.lsp.config("zls", {
            capabilities = capabilities,
        })

        -- nil_ls (Nix)
        vim.lsp.config("nil_ls", {
            capabilities = capabilities,
        })

        -- bashls (shell)
        vim.lsp.config("bashls", {
            capabilities = capabilities,
        })

        -- racket_langserver
        vim.lsp.config("racket_langserver", {
            capabilities = capabilities,
            cmd = { "racket", "--lib", "racket-langserver" },
            filetypes = {
                "racket",
                "scheme",
            },
        })

        -- Enable LSP servers
        -- lua
        vim.lsp.enable("lua_ls")
        -- web
        vim.lsp.enable("ts_ls")
        vim.lsp.enable("html")
        vim.lsp.enable("cssls")
        vim.lsp.enable("tailwindcss")
        vim.lsp.enable("astro")
        vim.lsp.enable("svelte")
        vim.lsp.enable("emmet_language_server")
        vim.lsp.enable("eslint")
        vim.lsp.enable("typos_lsp")
        -- backend / systems
        vim.lsp.enable("gopls")      -- Go
        vim.lsp.enable("pyright")    -- Python (types)
        vim.lsp.enable("ruff")       -- Python (lint/format)
        vim.lsp.enable("clangd")     -- C/C++
        vim.lsp.enable("zls")        -- Zig
        vim.lsp.enable("nil_ls")     -- Nix
        vim.lsp.enable("bashls")     -- shell
        vim.lsp.enable("racket_langserver")
    end,
}
