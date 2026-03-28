vim.cmd("let g:netrw_banner = 0")

vim.opt.nu = true
vim.opt.relativenumber = true
vim.cmd([[
  highlight LineNr guifg=#888888
]])

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

vim.opt.incsearch = true
vim.opt.inccommand = "split"
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- UI
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"

vim.cmd([[
  highlight Normal guibg=NONE ctermbg=NONE
  highlight NormalNC guibg=NONE ctermbg=NONE
  highlight Visual guibg=#2a2a2a guifg=NONE
]])

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"

vim.opt.backspace = {"start", "eol", "indent"}

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.cmdheight = 1
vim.opt.showmode = true
vim.opt.mousescroll = "ver:3,hor:1"

vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"

vim.opt.clipboard = "unnamedplus"
vim.opt.hlsearch = true

vim.opt.mouse = "a"
vim.g.editorconfig = true

-- Whitespace visibility
vim.opt.list = false
vim.opt.listchars = {
    tab = ">-",
    trail = "~",
    nbsp = "+",
    extends = ">",
    precedes = "<",
}

-- Highlight suspicious whitespace (trailing spaces, spaces before tabs)
vim.api.nvim_set_hl(0, "Whitespace", { fg = "#666666", bg = "NONE" })
vim.api.nvim_set_hl(0, "NonText", { fg = "#666666", bg = "NONE" })
vim.api.nvim_set_hl(0, "SpecialKey", { fg = "#666666", bg = "NONE" })
vim.api.nvim_set_hl(0, "ExtraWhitespace", { bg = "#51202A" })
local whitespace_group = vim.api.nvim_create_augroup("SethyWhitespace", { clear = true })

local function skip_extra_whitespace(buf)
    local filetype = vim.bo[buf].filetype
    local buftype = vim.bo[buf].buftype

    return filetype == "snacks_dashboard" or buftype == "nofile"
end

local function apply_extra_whitespace(pattern)
    if skip_extra_whitespace(0) then
        vim.fn.clearmatches()
        return
    end

    vim.fn.matchadd("ExtraWhitespace", pattern)
end

vim.api.nvim_create_autocmd("ColorScheme", {
    group = whitespace_group,
    callback = function()
        vim.api.nvim_set_hl(0, "Whitespace", { fg = "#666666", bg = "NONE" })
        vim.api.nvim_set_hl(0, "NonText", { fg = "#666666", bg = "NONE" })
        vim.api.nvim_set_hl(0, "SpecialKey", { fg = "#666666", bg = "NONE" })
        vim.api.nvim_set_hl(0, "ExtraWhitespace", { bg = "#51202A" })
    end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    group = whitespace_group,
    callback = function()
        apply_extra_whitespace([[\s\+$\| \+\ze\t]])
    end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
    group = whitespace_group,
    callback = function()
        apply_extra_whitespace([[\s\+\%#\@<!$\| \+\ze\t]])
    end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
    group = whitespace_group,
    callback = function()
        apply_extra_whitespace([[\s\+$\| \+\ze\t]])
    end,
})
