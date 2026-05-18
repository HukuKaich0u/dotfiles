require("Sethy.core.env").setup_luarocks()

require("Sethy.core")
require("Sethy.lazy")
require("Sethy.builtin")

local persisted_theme = vim.fn.stdpath("state") .. "/current-theme.lua"
if vim.fn.filereadable(persisted_theme) == 1 then
  dofile(persisted_theme)
else
  require("current-theme")
end
