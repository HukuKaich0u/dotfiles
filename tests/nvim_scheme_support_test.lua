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

local treesitter = read(".config/nvim/lua/Sethy/plugins/treesitter.lua")
assert_match(treesitter, '"scheme"', "treesitter should install the scheme parser")
assert_match(treesitter, '"racket"', "treesitter should install the racket parser")

local scheme = read(".config/nvim/lua/Sethy/plugins/scheme.lua")
assert_match(scheme, '"Olical/conjure"', "scheme plugin config should install Conjure")
assert_match(scheme, '"HiPhish/rainbow%-delimiters%.nvim"',
  "scheme plugin config should install rainbow delimiters")
assert_match(scheme, '"racket"', "scheme plugin config should target racket filetypes")
assert_match(scheme, '"scheme"', "scheme plugin config should target scheme filetypes")

local lspconfig = read(".config/nvim/lua/Sethy/plugins/lsp/lspconfig.lua")
local racket_block = extract_lsp_block(lspconfig, "racket_langserver")
assert_match(racket_block, "capabilities = capabilities",
  "racket_langserver should use shared LSP capabilities")
assert_match(racket_block, '"racket"', "racket_langserver should support racket filetypes")
assert_match(racket_block, '"racket%-langserver"', "racket_langserver should invoke the racket language server")
assert_match(lspconfig, 'vim%.lsp%.enable%("racket_langserver"%)',
  "lspconfig should enable racket_langserver")

local docs = read(".config/nvim/docs/plugins-guide.md")
assert_match(docs, "Conjure", "plugin guide should mention Conjure for Scheme workflows")
assert_match(docs, "racket%-langserver", "plugin guide should mention racket-langserver")

print("nvim scheme support tests passed")
