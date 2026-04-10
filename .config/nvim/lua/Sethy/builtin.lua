local function packadd(plugin)
    local ok, err = pcall(vim.cmd, "packadd " .. plugin)
    if not ok then
        vim.notify(("Failed to load builtin plugin %s: %s"):format(plugin, err), vim.log.levels.WARN)
    end
end

packadd("nvim.undotree")
packadd("nvim.difftool")

vim.keymap.set("n", "<leader>U", "<cmd>Undotree<CR>", {
    desc = "Open builtin undotree",
    silent = true,
})

vim.keymap.set("n", "<leader>gdt", ":DiffTool ", {
    desc = "Start builtin DiffTool",
})
