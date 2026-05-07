local M = {}

local reload_group = vim.api.nvim_create_augroup("SethyReload", { clear = true })

local function is_oil_buffer(bufnr)
    return vim.bo[bufnr].filetype == "oil"
end

local function is_reloadable_file_buffer(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end

    if vim.bo[bufnr].buftype ~= "" or vim.bo[bufnr].modified then
        return false
    end

    return vim.api.nvim_buf_get_name(bufnr) ~= ""
end

local function refresh_oil_window(winid)
    return pcall(vim.api.nvim_win_call, winid, function()
        require("oil.actions").refresh.callback({ force = true })
    end)
end

local function checktime_window(winid)
    return pcall(vim.api.nvim_win_call, winid, function()
        vim.cmd.checktime()
    end)
end

local function sync_window(winid, seen_buffers)
    local bufnr = vim.api.nvim_win_get_buf(winid)
    if seen_buffers[bufnr] then
        return { files = 0, oils = 0, skipped = 0 }
    end
    seen_buffers[bufnr] = true

    if is_oil_buffer(bufnr) then
        local ok = refresh_oil_window(winid)
        return { files = 0, oils = ok and 1 or 0, skipped = ok and 0 or 1 }
    end

    if vim.bo[bufnr].modified then
        return { files = 0, oils = 0, skipped = 1 }
    end

    if not is_reloadable_file_buffer(bufnr) then
        return { files = 0, oils = 0, skipped = 0 }
    end

    local ok = checktime_window(winid)
    return { files = ok and 1 or 0, oils = 0, skipped = ok and 0 or 1 }
end

function M.sync_current_tab()
    local counts = { files = 0, oils = 0, skipped = 0 }
    local seen_buffers = {}

    for _, winid in ipairs(vim.api.nvim_tabpage_list_wins(vim.api.nvim_get_current_tabpage())) do
        local result = sync_window(winid, seen_buffers)
        counts.files = counts.files + result.files
        counts.oils = counts.oils + result.oils
        counts.skipped = counts.skipped + result.skipped
    end

    vim.notify(
        string.format(
            "Checked %d file buffer(s), refreshed %d oil buffer(s), skipped %d modified/error buffer(s)",
            counts.files,
            counts.oils,
            counts.skipped
        ),
        vim.log.levels.INFO,
        { title = "Reload Tab" }
    )
end

function M.check_current_buffer()
    if vim.fn.mode() == "c" then
        return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    if is_oil_buffer(bufnr) or not is_reloadable_file_buffer(bufnr) then
        return
    end

    checktime_window(vim.api.nvim_get_current_win())
end

function M.setup()
    vim.api.nvim_create_user_command("ReloadTab", M.sync_current_tab, {
        desc = "Reload files and refresh oil in the current tab",
    })

    vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
        group = reload_group,
        callback = M.check_current_buffer,
        desc = "Reload unchanged file buffers when returning to Neovim",
    })
end

return M
