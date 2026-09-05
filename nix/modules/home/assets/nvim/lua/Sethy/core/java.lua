local M = {}

function M.root(bufnr)
    -- Search workspace markers before module-local build files.
    local root = vim.fs.root(bufnr, { { "settings.gradle", "settings.gradle.kts", "mvnw", "gradlew" } })
        or vim.fs.root(bufnr, ".git")
        or vim.fs.root(bufnr, { { "pom.xml", "build.gradle", "build.gradle.kts", "build.xml" } })
    local filename = vim.api.nvim_buf_get_name(bufnr)
    return root or (filename ~= "" and vim.fs.dirname(filename) or nil)
end

function M.workspace(root)
    -- Hash the full path: same basenames and slash/underscore variants stay distinct.
    root = vim.uv.fs_realpath(root) or root
    return vim.fn.stdpath("state")
        .. "/jdtls-workspaces/"
        .. vim.fn.fnamemodify(root, ":t")
        .. "-"
        .. vim.fn.sha256(root):sub(1, 16)
end

return M
