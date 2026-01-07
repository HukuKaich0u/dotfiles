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

        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        local cmp = require("cmp")

        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())

    end,
}

