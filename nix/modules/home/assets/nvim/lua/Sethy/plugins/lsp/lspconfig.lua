return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        { "antosha417/nvim-lsp-file-operations", config = true },
        "saghen/blink.cmp",
    },
    config = function()
        vim.lsp.config("*", { capabilities = require("blink.cmp").get_lsp_capabilities() })

        vim.api.nvim_create_autocmd("LspAttach", {
            group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
            callback = function(ev)
                local client = vim.lsp.get_client_by_id(ev.data.client_id)
                if not client then
                    return
                end
                local function map(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
                end
                map("n", "gR", "<cmd>Telescope lsp_references<CR>", "Show LSP references")
                map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
                map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", "Show LSP definitions")
                map("n", "gi", "<cmd>Telescope lsp_implementations<CR>", "Show LSP implementations")
                map("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", "Show LSP type definitions")
                map({ "n", "x" }, "<leader>vca", vim.lsp.buf.code_action, "Code actions")
                map({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code actions")
                map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
                map("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", "Buffer diagnostics")
                map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")
                map("n", "K", vim.lsp.buf.hover, "Hover documentation")
                map("n", "<leader>cs", "<cmd>Telescope lsp_document_symbols<CR>", "Document symbols")
                map("n", "<leader>cS", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", "Workspace symbols")
                map("n", "<leader>co", function()
                    if vim.bo[ev.buf].filetype == "java" then
                        require("jdtls").organize_imports()
                    else
                        vim.lsp.buf.code_action({
                            context = { only = { "source.organizeImports" }, diagnostics = {} },
                            apply = true,
                        })
                    end
                end, "Organize imports")
                map("n", "<leader>rs", function()
                    if vim.bo[ev.buf].filetype == "rust" then
                        vim.cmd.RustAnalyzer("restart")
                    elseif vim.bo[ev.buf].filetype == "java" then
                        vim.cmd.JdtRestart()
                    else
                        vim.cmd.LspRestart()
                    end
                end, "Restart language server")
                -- Keep insert-mode <C-h> (backspace) and Neovim's <C-s> signature help.
                if client:supports_method("textDocument/inlayHint") then
                    map("n", "<leader>ch", function()
                        local filter = { bufnr = ev.buf }
                        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
                    end, "Toggle inlay hints")
                end
            end,
        })

        vim.diagnostic.config({
            signs = {
                text = {
                    [vim.diagnostic.severity.ERROR] = " ",
                    [vim.diagnostic.severity.WARN] = " ",
                    [vim.diagnostic.severity.HINT] = "󰠠 ",
                    [vim.diagnostic.severity.INFO] = " ",
                },
            },
            severity_sort = true,
            float = { border = "rounded", source = "if_many" },
            virtual_text = { spacing = 2, source = "if_many" },
            underline = true,
            update_in_insert = false,
        })

        for name, config in pairs(require("Sethy.core.servers")) do
            vim.lsp.config(name, config)
            vim.lsp.enable(name)
        end
    end,
}
