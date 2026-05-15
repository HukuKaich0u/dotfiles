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
assert_match(mason, '"nil_ls"', "mason should install nil_ls for Nix")
assert_match(mason, '"bashls"', "mason should install bashls for shell scripts")
assert_match(mason, '"alejandra"', "mason should install alejandra for Nix formatting")
assert_match(mason, '"shfmt"', "mason should install shfmt for shell formatting")
assert_match(mason, '"shellcheck"', "mason should install shellcheck for shell diagnostics")

local lspconfig = read("nix/modules/home/assets/nvim/lua/Sethy/plugins/lsp/lspconfig.lua")
local nil_block = extract_lsp_block(lspconfig, "nil_ls")
local bash_block = extract_lsp_block(lspconfig, "bashls")

assert_match(nil_block, "capabilities = capabilities", "nil_ls should use shared LSP capabilities")
assert_match(bash_block, "capabilities = capabilities", "bashls should use shared LSP capabilities")
assert_match(lspconfig, 'vim%.lsp%.enable%("nil_ls"%)', "lspconfig should enable nil_ls")
assert_match(lspconfig, 'vim%.lsp%.enable%("bashls"%)', "lspconfig should enable bashls")

local treesitter = read("nix/modules/home/assets/nvim/lua/Sethy/plugins/treesitter.lua")
assert_match(treesitter, '"nix"', "treesitter should install the nix parser")
assert_match(treesitter, '"bash"', "treesitter should keep shell parser support")

local conform = read("nix/modules/home/assets/nvim/lua/Sethy/plugins/conform.lua")
assert_match(conform, 'nix = { "alejandra" }', "Nix files should format with alejandra")
assert_match(conform, 'sh = { "shfmt" }', "sh files should format with shfmt")
assert_match(conform, 'bash = { "shfmt" }', "bash files should format with shfmt")
assert_match(conform, 'zsh = { "shfmt" }', "zsh files should format with shfmt")
assert_match(conform, "nix = true", "nix should format on save")
assert_match(conform, "sh = true", "sh should format on save")
assert_match(conform, "bash = true", "bash should format on save")
assert_match(conform, "zsh = true", "zsh should format on save")

local docs = read("nix/modules/home/assets/nvim/docs/plugins-guide.md")
assert_match(docs, "| Nix | alejandra |", "plugin guide should document Nix formatting")
assert_match(docs, "| Shell %(sh/bash/zsh%) | shfmt |", "plugin guide should document shell formatting")

print("nvim nix and shell support tests passed")
