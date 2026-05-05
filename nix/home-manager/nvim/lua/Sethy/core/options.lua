local env = require("Sethy.core.env")

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
vim.opt.background = "light"
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"

vim.cmd([[
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

if env.clipboard_available() then
    vim.opt.clipboard = "unnamedplus"
else
    vim.opt.clipboard = ""
end
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
