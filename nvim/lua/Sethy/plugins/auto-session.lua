return {
    "rmagatti/auto-session",
    config = function()
        local auto_session = require("auto-session")

        auto_session.setup({
            auto_restore_enabled = false,
            auto_session_suppress_dirs = { "~/", "~/Downloads", "~/Documents", "~/Desktop" },
        })

        vim.keymap.set("n", "<leader>wr", "<cmd>AutoSession restore<CR>", { desc = "Restore session for cwd" }) -- resto last workspace session for current directory
        vim.keymap.set("n", "<leader>ws", "<cmd>AutoSession save<CR>", { desc = "Save session for auto session root dir" }) -- save workspace session for current working directory
    end,
}
