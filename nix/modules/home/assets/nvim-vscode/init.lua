local vscode = require("vscode")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

local function map_action(lhs, command, description)
  vim.keymap.set("n", lhs, function()
    vscode.action(command)
  end, { silent = true, desc = description })
end

map_action("<leader>ee", "workbench.view.explorer", "Open Explorer")
map_action("<leader>pf", "workbench.action.quickOpen", "Quick Open")
map_action("<leader>ps", "workbench.action.findInFiles", "Find in Files")
vim.keymap.set("n", "<leader>pws", function()
  vscode.action("workbench.action.findInFiles", {
    args = { query = vim.fn.expand("<cword>") },
  })
end, { silent = true, desc = "Find Word in Files" })
map_action("<leader>gg", "workbench.view.scm", "Open Source Control")
map_action("gd", "editor.action.revealDefinition", "Go to Definition")
map_action("gR", "editor.action.goToReferences", "Go to References")
map_action("gi", "editor.action.goToImplementation", "Go to Implementation")
map_action("gt", "editor.action.goToTypeDefinition", "Go to Type Definition")
map_action("K", "editor.action.showHover", "Show Hover")
map_action("<leader>rn", "editor.action.rename", "Rename Symbol")
map_action("<leader>vca", "editor.action.quickFix", "Code Action")
map_action("<leader>d", "editor.action.showHover", "Show Hover")
map_action("<C-h>", "workbench.action.navigateLeft", "Navigate Left")
map_action("<C-j>", "workbench.action.navigateDown", "Navigate Down")
map_action("<C-k>", "workbench.action.navigateUp", "Navigate Up")
map_action("<C-l>", "workbench.action.navigateRight", "Navigate Right")
