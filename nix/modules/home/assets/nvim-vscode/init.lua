local vscode = require("vscode")

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

local function map_action(lhs, command, description)
  vim.keymap.set("n", lhs, function()
    vscode.action(command)
  end, { silent = true, desc = description })
end

local function map_task(lhs, task, description)
  vim.keymap.set("n", lhs, function()
    vscode.action("workbench.action.tasks.runTask", { args = { task } })
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
-- Source Control はフォーカスがコミット入力欄に入るため、開いた直後に
-- 変更リストへフォーカスを移す。これで再度 <leader>gg した時に
-- keybindings.json 側のトグル (閉じる) が効く。
vim.keymap.set("n", "<leader>gg", function()
  vscode.action("workbench.view.scm", {
    callback = function()
      vscode.action("widgetNavigation.focusNext")
    end,
  })
end, { silent = true, desc = "Open Source Control" })
-- Markdown ソース編集中 → プレビューへ。markdown.showPreview は同じタブで
-- source ⇄ preview をトグルする。プレビュー表示中はテキストフォーカスが
-- 無いため keybindings.json 側の space m p が戻り側を担当する。
map_action("<leader>mp", "markdown.showPreview", "Toggle Markdown Preview")
map_task("<leader>cb", "C: Build active file (choose compiler)", "Build C File")
map_task("<leader>cr", "C: Run active file (choose compiler)", "Run C File")
map_action("<leader>cd", "workbench.action.debug.start", "Debug C File")
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
