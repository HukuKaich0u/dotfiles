return {
    "windwp/nvim-autopairs",
    event = { "InsertEnter" },
    dependencies = {
        "hrsh7th/nvim-cmp",
    },
    config = function()
        local autopairs = require("nvim-autopairs")

        autopairs.setup({
            check_ts = true,
            ts_config = {
                lua = { "string" },
                javascript = { "template_string" },
                typescript = { "template_string" },
                tsx = { "template_string" },
                python = { "string" },
                go = { "interpreted_string_literal", "raw_string_literal", "rune_literal" },
                rust = { "string_literal", "raw_string_literal", "char_literal" },
                c = { "string_literal", "char_literal" },
                cpp = { "string_literal", "raw_string_literal", "char_literal" },
                ruby = { "string" },
                java = false,
            },
        })
        -- Rust lifetime ('a) と衝突しやすいので、Rustではシングルクォートの自動ペアを無効化
        local single_quote_rules = autopairs.get_rules("'") or {}
        for _, rule in ipairs(single_quote_rules) do
            rule.not_filetypes = rule.not_filetypes or {}
            if not vim.tbl_contains(rule.not_filetypes, "rust") then
                table.insert(rule.not_filetypes, "rust")
            end
        end

        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        local cmp = require("cmp")

        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

    end,
}
