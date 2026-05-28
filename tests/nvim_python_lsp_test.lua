local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")

local function read(path)
  local file = assert(io.open(repo_root .. "/" .. path, "r"))
  local content = file:read("*a")
  file:close()
  return content
end

local function assert_match(content, pattern, message)
  if not content:match(pattern) then
    error(message .. "\nmissing pattern: " .. pattern)
  end
end

local function extract_lsp_block(content, server_name)
  local marker = 'vim.lsp.config("' .. server_name .. '"'
  local start_pos = content:find(marker, 1, true)
  if not start_pos then
    error("missing LSP block for " .. server_name)
  end

  local next_pos = content:find('vim.lsp.config("', start_pos + #marker, true)
  if not next_pos then
    next_pos = #content + 1
  end

  return content:sub(start_pos, next_pos - 1)
end

local lspconfig = read("nix/modules/home/assets/nvim/lua/Sethy/plugins/lsp/lspconfig.lua")
local pyright_block = extract_lsp_block(lspconfig, "pyright")

assert_match(pyright_block, 'diagnosticMode = "openFilesOnly"',
  "pyright should limit analysis to open files to reduce background churn")

local noice = read("nix/modules/home/assets/nvim/lua/Sethy/plugins/noice.lua")
assert_match(noice, "progress = {%s*enabled = false,",
  "noice should disable LSP progress popups to avoid constant pyright status updates")

print("nvim python lsp tests passed")
