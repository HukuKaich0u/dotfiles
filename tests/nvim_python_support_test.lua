local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo_root .. "/nix/modules/home/assets/nvim")
local python = require("Sethy.core.python")
local tmp = vim.fn.tempname()
local old_venv, old_conda = vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX
local function environment(name)
  local path = tmp .. "/" .. name
  vim.fn.mkdir(path .. "/bin", "p")
  vim.fn.writefile({ "#!/bin/sh", "exit 0" }, path .. "/bin/python")
  vim.fn.setfperm(path .. "/bin/python", "rwx------")
  return path
end
local ok, err = pcall(function()
  vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = nil, nil
  assert(python.interpreter(tmp) == nil, "Do not override Pyright's own environment resolution without a venv")
  local local_env = environment(".venv")
  assert(python.interpreter(tmp) == local_env .. "/bin/python", "Detect uv/project .venv without shell activation")
  vim.env.VIRTUAL_ENV = environment("active")
  assert(python.interpreter(tmp) == vim.env.VIRTUAL_ENV .. "/bin/python", "An activated venv is an explicit choice")
  vim.env.VIRTUAL_ENV = tmp .. "/missing"
  assert(python.interpreter(tmp) == local_env .. "/bin/python", "Ignore stale VIRTUAL_ENV paths")
  vim.env.CONDA_PREFIX = environment("conda")
  assert(
    python.interpreter(tmp .. "/other") == vim.env.CONDA_PREFIX .. "/bin/python",
    "Support an active Conda environment"
  )
  local config = { root_dir = tmp, settings = { python = { pythonPath = "/explicit/python" } } }
  python.before_init(nil, config)
  assert(config.settings.python.pythonPath == "/explicit/python", "Preserve an explicit interpreter setting")
  config = { root_dir = tmp, settings = { python = { analysis = { typeCheckingMode = "strict" } } } }
  python.before_init(nil, config)
  assert(config.settings.python.pythonPath == local_env .. "/bin/python")
  assert(
    config.settings.python.analysis.typeCheckingMode == "strict",
    "Environment detection must preserve analysis settings"
  )
end)
vim.env.VIRTUAL_ENV, vim.env.CONDA_PREFIX = old_venv, old_conda
vim.fn.delete(tmp, "rf")
if not ok then
  error(err)
end
print("nvim python support tests passed")
