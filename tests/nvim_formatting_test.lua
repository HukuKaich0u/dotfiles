local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config_root = repo_root .. "/nix/modules/home/assets/nvim"
local plugin_root = vim.env.NVIM_TEST_PLUGIN_DIR or (vim.fn.stdpath("data") .. "/lazy")
if vim.fn.isdirectory(plugin_root .. "/conform.nvim") == 0 then
  print("SKIP: formatting integration requires conform.nvim (set NVIM_TEST_PLUGIN_DIR)")
  return
end
vim.opt.runtimepath:prepend(plugin_root .. "/conform.nvim")
local spec = dofile(config_root .. "/lua/Sethy/plugins/conform.lua")
spec.config(nil, spec.opts)
local conform = require("conform")
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
tmp = vim.uv.fs_realpath(tmp)
local function write(path, lines)
  vim.fn.mkdir(vim.fs.dirname(tmp .. "/" .. path), "p")
  vim.fn.writefile(lines, tmp .. "/" .. path)
end
local function open(path, ft)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_buf_set_name(bufnr, tmp .. "/" .. path)
  vim.bo[bufnr].filetype = ft
  return bufnr
end
local function chosen(bufnr)
  return conform.list_formatters_for_buffer(bufnr)[1]
end

local ok, err = pcall(function()
  local ts = open("app/src/main.ts", "typescript")
  assert(chosen(ts) == "prettier", "Unconfigured TS projects use Prettier, not biome-check")
  write("app/biome.json", { "{}" })
  assert(chosen(ts) == "biome", "Explicit Biome config must win over the default")
  write("app/.prettierrc", { "{}" })
  assert(chosen(ts) == "prettier", "Prettier can own formatting while Biome owns lint")
  write("app/src/biome.jsonc", { "{}" })
  assert(chosen(ts) == "biome", "The nearest nested formatter config must win: " .. vim.inspect({
    biome = conform.get_formatter_info("biome", ts).cwd,
    prettier = conform.get_formatter_info("prettier", ts).cwd,
  }))
  vim.fn.delete(tmp .. "/app/src/biome.jsonc")
  vim.fn.delete(tmp .. "/app/.prettierrc")
  write("app/package.json", { '{"prettier":{"semi":false}}' })
  assert(chosen(ts) == "prettier", "Support package.json Prettier settings")

  for _, ft in ipairs({ "rust", "typescript", "typescriptreact", "go", "java", "python", "c", "cpp" }) do
    vim.bo[ts].filetype = ft
    assert(spec.opts.format_on_save(ts), ft .. " must format on save")
  end
  vim.cmd.FormatToggle()
  assert(spec.opts.format_on_save(ts) == nil, "Per-buffer toggle must stop autoformat")
  vim.cmd.FormatToggle()
  vim.cmd("FormatToggle!")
  assert(spec.opts.format_on_save(ts) == nil, "Global toggle must stop autoformat")
  vim.cmd("FormatToggle!")
  vim.bo[ts].filetype = "zsh"
  assert(spec.opts.format_on_save(ts) == nil, "Never pass zsh syntax to shfmt")
  assert(#conform.list_formatters_for_buffer(ts) == 0)

  -- A real formatter must preserve ignored files and avoid lint/import changes.
  local biome = conform.get_formatter_info("biome", ts)
  if vim.fn.executable(biome.command) == 1 then
    vim.fn.delete(tmp .. "/app/package.json")
    write("app/biome.json", { "{}" })
    vim.bo[ts].filetype = "typescript"
    vim.api.nvim_buf_set_lines(ts, 0, -1, false, { 'import { unused } from "./other";', "const value={answer:42};" })
    local format_error
    conform.format({ bufnr = ts, async = false }, function(e)
      format_error = e
    end)
    assert(not format_error, format_error)
    local result = table.concat(vim.api.nvim_buf_get_lines(ts, 0, -1, false), "\n")
    assert(result:find("unused", 1, true), "Formatting must not delete unused imports")
    assert(result:find("answer: 42", 1, true), "Biome must actually format the buffer")

    write("app/biome.json", { '{"files":{"includes":["**","!**/ignored.ts"]}}' })
    local unformatted = "const value={answer:42};"
    write("app/ignored.ts", { unformatted })
    local ignored = open("app/ignored.ts", "typescript")
    vim.api.nvim_buf_set_lines(ignored, 0, -1, false, { unformatted })
    conform.format({ bufnr = ignored, async = false }, function(e)
      format_error = e
    end)
    assert(not format_error, format_error)
    assert(
      vim.api.nvim_buf_get_lines(ignored, 0, -1, false)[1] == unformatted,
      "Ignored files must remain unchanged without another formatter taking over"
    )
  else
    print("SKIP: real Biome formatting (biome not on PATH)")
  end
end)
vim.fn.delete(tmp, "rf")
if not ok then
  error(err)
end
print("nvim formatting tests passed")
