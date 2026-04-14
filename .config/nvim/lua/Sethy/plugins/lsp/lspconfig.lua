return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        { "antosha417/nvim-lsp-file-operations", config = true },
        "mfussenegger/nvim-dap",
        "MunifTanjim/nui.nvim",
        "nvim-java/nvim-java",
    },
    config = function()
        require("java").setup({
            jdk = {
                auto_install = false,
            },
            java_test = {
                enable = true,
            },
            java_debug_adapter = {
                enable = true,
            },
            spring_boot_tools = {
                enable = false,
            },
        })

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

                if client:supports_method("textDocument/completion") then
                    vim.lsp.completion.enable(true, client.id, ev.buf, {
                        autotrigger = true,
                    })

                    vim.keymap.set("i", "<C-Space>", function()
                        vim.lsp.completion.get()
                    end, opts)
                end

                if client.name == "jdtls" then
                    opts.desc = "Java organize imports"
                    vim.keymap.set("n", "<leader>jo", function()
                        vim.lsp.buf.code_action({
                            apply = true,
                            context = {
                                only = { "source.organizeImports" },
                            },
                        })
                    end, opts)

                    local ok, java = pcall(require, "java")
                    if ok then
                        opts.desc = "Java run main class"
                        vim.keymap.set("n", "<leader>jr", function()
                            java.runner.built_in.run_app()
                        end, opts)

                        opts.desc = "Java stop app"
                        vim.keymap.set("n", "<leader>jS", function()
                            java.runner.built_in.stop_app()
                        end, opts)

                        opts.desc = "Java run nearest test"
                        vim.keymap.set("n", "<leader>jt", function()
                            java.test.run_current_method()
                        end, opts)

                        opts.desc = "Java run test class"
                        vim.keymap.set("n", "<leader>jT", function()
                            java.test.run_current_class()
                        end, opts)

                        opts.desc = "Java debug nearest test"
                        vim.keymap.set("n", "<leader>jd", function()
                            java.test.debug_current_method()
                        end, opts)

                        opts.desc = "Java debug test class"
                        vim.keymap.set("n", "<leader>jD", function()
                            java.test.debug_current_class()
                        end, opts)

                        opts.desc = "Java build workspace"
                        vim.keymap.set("n", "<leader>jb", function()
                            java.build.build_workspace()
                        end, opts)

                        opts.desc = "Java last test report"
                        vim.keymap.set("n", "<leader>jv", function()
                            java.test.view_last_report()
                        end, opts)

                        opts.desc = "Java choose runtime"
                        vim.keymap.set("n", "<leader>jR", function()
                            java.settings.change_runtime()
                        end, opts)
                    end
                end
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

        vim.opt.completeopt:append({ "menuone", "noselect", "popup" })

        -- Configure and enable LSP servers
        -- lua_ls
        vim.lsp.config("lua_ls", {
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
            filetypes = {
                "css",
                "eruby",
                "html",
                "javascript",
                "javascriptreact",
                "less",
                "sass",
                "scss",
                "pug",
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

        -- emmet_ls
        vim.lsp.config("emmet_ls", {
            filetypes = {
                "html",
                "typescriptreact",
                "javascriptreact",
                "css",
                "sass",
                "scss",
                "less",
                "svelte",
            },
        })

        -- ts_ls (TypeScript/JavaScript)
        vim.lsp.config("ts_ls", {
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
        vim.lsp.config("ruff", {})

        -- clangd (C/C++)
        vim.lsp.config("clangd", {
            cmd = {
                "clangd",
                "--background-index",
                "--clang-tidy",
                "--header-insertion=iwyu",
                "--completion-style=detailed",
            },
        })

        -- jdtls (Java)
        vim.lsp.config("jdtls", {
            settings = {
                java = {
                    eclipse = {
                        downloadSources = true,
                    },
                    maven = {
                        downloadSources = true,
                    },
                    configuration = {
                        updateBuildConfiguration = "interactive",
                    },
                    references = {
                        includeDecompiledSources = true,
                    },
                    implementationsCodeLens = {
                        enabled = true,
                    },
                    referencesCodeLens = {
                        enabled = true,
                    },
                    format = {
                        enabled = true,
                    },
                    signatureHelp = {
                        enabled = true,
                    },
                    saveActions = {
                        organizeImports = true,
                    },
                    contentProvider = {
                        preferred = "fernflower",
                    },
                    sources = {
                        organizeImports = {
                            starThreshold = 9999,
                            staticStarThreshold = 9999,
                        },
                    },
                },
            },
        })

        -- zls (Zig)
        vim.lsp.config("zls", {})

        -- Enable LSP servers
        -- lua
        vim.lsp.enable("lua_ls")
        -- web
        vim.lsp.enable("ts_ls")
        vim.lsp.enable("html")
        vim.lsp.enable("cssls")
        vim.lsp.enable("tailwindcss")
        vim.lsp.enable("astro")
        vim.lsp.enable("emmet_language_server")
        vim.lsp.enable("emmet_ls")
        vim.lsp.enable("eslint")
        -- backend / systems
        vim.lsp.enable("gopls")      -- Go
        vim.lsp.enable("pyright")    -- Python (types)
        vim.lsp.enable("ruff")       -- Python (lint/format)
        vim.lsp.enable("clangd")     -- C/C++
        vim.lsp.enable("jdtls")      -- Java
        vim.lsp.enable("zls")        -- Zig
    end,
}
