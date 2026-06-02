local root_markers = {
    "settings.gradle",
    "settings.gradle.kts",
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "mvnw",
    "gradlew",
    ".git",
}

local root_dir = vim.fs.root(0, root_markers)
if root_dir == nil then
    return
end

local workspace_name = vim.fn.fnamemodify(root_dir, ":p"):gsub("[/\\:]", "_")
local workspace_dir = vim.fn.stdpath("state") .. "/jdtls-workspaces/" .. workspace_name

vim.lsp.start({
    name = "jdtls",
    cmd = {
        "jdtls",
        "--jvm-arg=-Xms256m",
        "--jvm-arg=-Xmx2g",
        "-data",
        workspace_dir,
    },
    root_dir = root_dir,
    capabilities = require("blink.cmp").get_lsp_capabilities(),
    reuse_client = function(client, config)
        return client.name == config.name and client.config.root_dir == config.root_dir
    end,
})
