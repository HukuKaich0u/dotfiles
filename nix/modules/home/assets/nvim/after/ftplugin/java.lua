if vim.bo.buftype ~= "" then
    return
end

local java = require("Sethy.core.java")
local root_dir = java.root(0)
if not root_dir then
    return
end
if vim.fn.executable("jdtls") == 0 then
    vim.notify("jdtls is not installed yet. Run :MasonInstall jdtls, then reopen the Java buffer.", vim.log.levels.WARN)
    return
end

require("jdtls").start_or_attach({
    name = "jdtls",
    cmd = {
        "jdtls",
        "--jvm-arg=-Xms256m",
        "--jvm-arg=-Xmx2g",
        "-data",
        java.workspace(root_dir),
    },
    root_dir = root_dir,
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    settings = {
        java = {
            signatureHelp = { enabled = true },
            contentProvider = { preferred = "fernflower" },
            inlayHints = { parameterNames = { enabled = "literals" } },
        },
    },
})

vim.keymap.set("n", "<leader>cv", function()
    require("jdtls").extract_variable()
end, { buffer = true, desc = "Extract Java variable" })
vim.keymap.set(
    "x",
    "<leader>cv",
    "<Esc><cmd>lua require('jdtls').extract_variable(true)<CR>",
    { buffer = true, desc = "Extract Java variable" }
)
vim.keymap.set(
    "x",
    "<leader>cm",
    "<Esc><cmd>lua require('jdtls').extract_method(true)<CR>",
    { buffer = true, desc = "Extract Java method" }
)
