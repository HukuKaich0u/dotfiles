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

local mason = read("nix/modules/home/assets/nvim/lua/Sethy/plugins/lsp/mason.lua")
assert_match(mason, '"typos_lsp"', "mason should install typos_lsp")

local lspconfig = read("nix/modules/home/assets/nvim/lua/Sethy/plugins/lsp/lspconfig.lua")
local typos_block = extract_lsp_block(lspconfig, "typos_lsp")

assert_match(lspconfig, 'vim%.lsp%.enable%("typos_lsp"%)', "lspconfig should enable typos_lsp")
assert_match(typos_block, 'cmd = { "typos%-lsp" }', "typos_lsp should use the typos-lsp executable")
assert_match(typos_block, 'init_options = {', "typos_lsp should define init_options")
assert_match(typos_block, 'config = vim%.fn%.stdpath%("config"%) %.%. "/typos%.toml"',
  "typos_lsp should point at the global typos config file")

local typos_toml = read("nix/modules/home/assets/nvim/typos.toml")
assert_match(typos_toml, "%[default%.extend%-words%]", "global typos config should define extend-words")
assert_match(typos_toml, "%[default%.extend%-identifiers%]",
  "global typos config should define extend-identifiers for case-sensitive allowlists")

print("nvim typos lsp tests passed")
