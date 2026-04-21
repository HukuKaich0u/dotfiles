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

local function assert_no_match(content, pattern, message)
  if content:match(pattern) then
    error(message .. "\nunexpected pattern: " .. pattern)
  end
end

local mason = read(".config/nvim/lua/Sethy/plugins/lsp/mason.lua")
assert_match(mason, '"svelte"', "mason should install the svelte language server")

local cmp = read(".config/nvim/lua/Sethy/plugins/nvim-cmp.lua")
assert_match(cmp, '"hrsh7th/cmp%-nvim%-lsp"', "cmp should depend on cmp-nvim-lsp")
assert_match(cmp, '{ name = "nvim_lsp" }', "cmp should expose nvim_lsp completions")
assert_match(cmp, "%['<C%-n>'%] = cmp%.mapping%(select_next_item%)",
  "cmp should use Ctrl-n for next completion item")
assert_match(cmp, "%['<C%-p>'%] = cmp%.mapping%(select_prev_item%)",
  "cmp should use Ctrl-p for previous completion item")
assert_no_match(cmp, "%['<C%-j>'%] = cmp%.mapping%(select_next_item%)",
  "cmp should not use Ctrl-j for next completion item")
assert_no_match(cmp, "%['<C%-k>'%] = cmp%.mapping%(select_prev_item%)",
  "cmp should not use Ctrl-k for previous completion item")

local lspconfig = read(".config/nvim/lua/Sethy/plugins/lsp/lspconfig.lua")
assert_match(lspconfig, 'capabilities = require%("cmp_nvim_lsp"%)%.default_capabilities%(%)',
  "lspconfig should derive capabilities from cmp-nvim-lsp")
assert_match(lspconfig, 'vim%.lsp%.config%("svelte"', "lspconfig should configure the svelte language server")
assert_match(lspconfig, 'vim%.lsp%.enable%("svelte"%)', "lspconfig should enable the svelte language server")

local conform = read(".config/nvim/lua/Sethy/plugins/conform.lua")
assert_match(conform, 'astro = { "prettier" }', "astro should format with prettier")
assert_match(conform, 'svelte = { "prettier" }', "svelte should format with prettier")
assert_match(conform, "format_on_save", "web files should format on save")

local tailwind = read(".config/nvim/lua/Sethy/plugins/tailwind-tools.lua")
assert_match(tailwind, '"javascriptreact"', "tailwind colorizer should support javascriptreact")
assert_match(tailwind, '"typescriptreact"', "tailwind colorizer should support typescriptreact")
assert_match(tailwind, '"astro"', "tailwind colorizer should support astro")

print("nvim web support tests passed")
