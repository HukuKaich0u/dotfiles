-- Shared by LSP setup and Mason so installation and activation stay in sync.
-- Rust and Java have dedicated clients (rustaceanvim / nvim-jdtls).
return {
    ts_ls = {
        init_options = {
            preferences = {
                includeCompletionsForModuleExports = true,
                includeCompletionsForImportStatements = true,
                includeInlayParameterNameHints = "literals",
                includeInlayFunctionParameterTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
            },
        },
    },
    -- Upstream root detection activates these only in configured projects.
    biome = {},
    eslint = { settings = { format = false, workingDirectory = { mode = "auto" } } },
    gopls = {
        settings = {
            gopls = {
                analyses = { unusedparams = true },
                staticcheck = true,
                gofumpt = true,
                hints = {
                    assignVariableTypes = true,
                    compositeLiteralFields = true,
                    constantValues = true,
                    functionTypeParameters = true,
                    parameterNames = true,
                    rangeVariableTypes = true,
                },
            },
        },
    },
    pyright = {
        before_init = require("Sethy.core.python").before_init,
        settings = {
            pyright = { disableOrganizeImports = true },
            python = {
                analysis = {
                    diagnosticMode = "openFilesOnly",
                    typeCheckingMode = "basic",
                    autoSearchPaths = true,
                    useLibraryCodeForTypes = true,
                },
            },
        },
    },
    ruff = {
        on_attach = function(client)
            -- Pyright owns type information and hover; Ruff owns lint and imports.
            client.server_capabilities.hoverProvider = false
        end,
    },
    clangd = {
        cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
        },
    },
    -- Support files used alongside the main languages and in these dotfiles.
    lua_ls = {
        settings = {
            Lua = {
                runtime = { version = "LuaJIT" },
                diagnostics = { globals = { "vim" } },
                completion = { callSnippet = "Replace" },
                workspace = {
                    checkThirdParty = false,
                    library = { vim.env.VIMRUNTIME .. "/lua", vim.fn.stdpath("config") .. "/lua" },
                },
            },
        },
    },
    nil_ls = {},
    bashls = {},
    html = { init_options = { provideFormatter = false } },
    cssls = {},
    tailwindcss = {},
    emmet_language_server = {
        filetypes = { "css", "html", "less", "sass", "scss", "javascriptreact", "typescriptreact" },
    },
    typos_lsp = { init_options = { config = vim.fn.stdpath("config") .. "/typos.toml" } },
}
