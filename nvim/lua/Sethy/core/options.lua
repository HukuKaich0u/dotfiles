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

vim.opt.mousescroll = "ver:1,hor:1"

vim.opt.isfname:append("@-@")
vim.opt.updatetime = 50
vim.opt.colorcolumn = "80"

vim.opt.clipboard = "unnamedplus"
vim.opt.hlsearch = true

vim.opt.mouse = "a"
vim.g.editorconfig = true
