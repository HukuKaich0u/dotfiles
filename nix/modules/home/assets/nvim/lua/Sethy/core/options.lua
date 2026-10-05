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
vim.opt.autoread = true

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

-- 80 桁の目安線はコードのときだけ出す。文章・help・plugin の画面 (explorer / picker / terminal) では消す
local prose_filetypes = {
    markdown = true,
    text = true,
    help = true,
    gitcommit = true,
}
vim.opt.colorcolumn = ""
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    group = vim.api.nvim_create_augroup("SethyColorColumn", { clear = true }),
    callback = function(args)
        local bo = vim.bo[args.buf]
        local is_code = bo.buftype == "" and bo.filetype ~= "" and not prose_filetypes[bo.filetype]
        for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
            vim.api.nvim_set_option_value("colorcolumn", is_code and "80" or "", { scope = "local", win = win })
        end
    end,
})

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
