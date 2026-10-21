return {
    -- here only for wrapping html tags
    -- emmet_language_server is provided by Nix.
        "olrtg/nvim-emmet",
        config = function()
            vim.keymap.set({ "n", "v" }, '<leader>xe', require('nvim-emmet').wrap_with_abbreviation)
        end
}
