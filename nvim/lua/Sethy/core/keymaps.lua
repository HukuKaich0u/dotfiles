local opts = { noremap = true, silent = true }

vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

vim.keymap.set("x", "K", [[:<C-u>m '<-2<CR>gv=gv]], { desc = "moves lines up in visual selection" })
vim.keymap.set("x", "J", [[:<C-u>m '>+1<CR>gv=gv]], { desc = "moves lines down in visual selection" })

vim.keymap.set("n", "J", "mzJ'z")
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "move down in buffer with cursor centered"})
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "move up in buffer with cursor centered"})

vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

vim.keymap.set("v", "<", "<gv", opts)
vim.keymap.set("v", ">", ">gv", opts)

-- Paste without replacing clipboard content
vim.keymap.set("x", "<leader>p", [["_dP]])

vim.keymap.set("v", "p", '"_dp', opts)

vim.keymap.set({ "n", "v" }, "<leader>d", [["_d"_d]])

vim.keymap.set("n", "<C-c>", ":nohl<CR>", { desc = "Clear search hl", silent = true })

vim.keymap.set("n", "<leader>f", vim.lsp.buf.format)
vim.keymap.set("n", "Q", "<nop>")
vim.keymap.set("n", "x", '"_x', opts) -- prevents deleted characters from copying to clipboard

vim.keymap.set("n", "<leader>r", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word cursor in on globally" })
vim.keymap.set("n", "<leader>x", "<cmd>!chmod +x %<CR>", { silent = true, desc = "makes file executable" })

vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking (copying) text",
    group = vim.api.nvim_create_augroup("kickstart-highlight-yank", { clear = true}),
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- tab stuff
vim.keymap.set("n", "<leader>to", "<cmd>tabnew<CR>")    -- open new tab
vim.keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>")  -- close current tab
vim.keymap.set("n", "<leader>tn", "<cmd>tabn<CR>")      -- go to next
vim.keymap.set("n", "<leader>tp", "<cmd>tabp<CR>")      -- go to pre
vim.keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>")  -- open current tab in new tab

-- Split
vim.keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" })
vim.keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" })
vim.keymap.set("n", "<leader>se", "<C-w>=", { desc = "Make splits equal size" }) -- make split windowss equal width and height
vim.keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" })

vim.keymap.set("n", "<leader>e", ":e %:h<CR>", { desc = "Open netrw in file directory" })

-- Copy filepath to the clipboard
vim.keymap.set("n", "<leader>fp", function()
    local filePath = vim.fn.expand("%:~") -- Gets the file path relative to the home directory
    vim.fn.setreg("+", filePath) -- Copy the file path to the clipboard register
    print("File path copied to clipboard: " .. filePath)
end, { desc = "Copy file path to clipboard" })

-- Lazy.nvim UI
vim.keymap.set("n", "<leader>l", "<cmd>Lazy<CR>", { desc = "Open Lazy UI", silent = true })
