return {
    "kawre/leetcode.nvim",
    cmd = "Leet",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    opts = {
        lang = "rust",
        cn = {
            enabled = false,
        },
        plugins = {
            non_standalone = true,
        },
        picker = {
            provider = "snacks-picker",
        },
    },
}
