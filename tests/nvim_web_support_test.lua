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

local mason = read(".config/nvim/lua/Sethy/plugins/lsp/mason.lua")
assert_match(mason, '"svelte"', "mason should install the svelte language server")
assert_match(mason, '"emmet_language_server"', "mason should install emmet_language_server")
assert_no_match(mason, '"emmet_ls"', "mason should not install emmet_ls")

local blink = read(".config/nvim/lua/Sethy/plugins/blink-cmp.lua")
assert_match(blink, '"Saghen/blink%.cmp"', "blink config should install blink.cmp")
assert_match(blink, 'version = "1%.%*"', "blink config should pin the stable major version")
assert_match(blink, 'preset = "luasnip"', "blink config should keep LuaSnip snippets")
assert_match(blink, '%["<C%-n>"%] = { "select_next", "fallback" }',
  "blink config should use Ctrl-n for next completion item")
assert_match(blink, '%["<C%-p>"%] = { "select_prev", "fallback" }',
  "blink config should use Ctrl-p for previous completion item")
assert_match(blink, '%["<C%-Space>"%] = { "show", "show_documentation", "hide_documentation" }',
  "blink config should use Ctrl-Space to open completion")
assert_no_match(blink, '%["<C%-j>"%] =',
  "blink config should not use Ctrl-j for next completion item")
assert_no_match(blink, '%["<C%-k>"%] =',
  "blink config should not use Ctrl-k for previous completion item")
assert_match(blink, 'ghost_text = {', "blink config should configure insert ghost text explicitly")
assert_match(blink, 'show_with_selection = true',
  "blink insert ghost text should only appear for the selected completion")
assert_match(blink, 'auto_show = true',
  "blink insert documentation should auto-show to increase menu information density")
assert_match(blink, 'auto_show_delay_ms = 200',
  "blink insert documentation should wait briefly before auto-showing")
assert_match(blink, 'border = "rounded"', "blink popups should use rounded borders")
assert_match(blink, '"source_name"', "blink menu should display source names")
assert_match(blink, 'lsp = {%s*name = "%[LSP%]"', "blink sources should label LSP items clearly")
assert_match(blink, 'buffer = {%s*name = "%[Buffer%]"', "blink sources should label buffer items clearly")
assert_match(blink, 'path = {%s*name = "%[Path%]"', "blink sources should label path items clearly")
assert_match(blink, 'snippets = {%s*name = "%[Snip%]"', "blink sources should label snippet items clearly")
assert_match(blink, '"BlinkCmpKindFunction"',
  "blink config should define a function kind highlight")
assert_match(blink, '"BlinkCmpKindVariable"',
  "blink config should define a variable kind highlight")
assert_match(blink, '"BlinkCmpKindClass"',
  "blink config should define a class kind highlight")
assert_match(blink, '"BlinkCmpKindKeyword"',
  "blink config should define a keyword kind highlight")
assert_match(blink, '"BlinkCmpSource"',
  "blink config should define a dedicated source highlight")
assert_match(blink, 'cmdline = {', "blink config should configure cmdline separately")
assert_match(blink, 'preset = "cmdline"', "blink cmdline should use the dedicated preset")
assert_match(blink, 'auto_show = false', "blink cmdline should not auto-show completions")
assert_match(blink, 'ghost_text = {', "blink cmdline should configure ghost text explicitly")
assert_match(blink, 'enabled = false', "blink cmdline should disable ghost text")
assert_no_match(blink, 'preset = "inherit"', "blink cmdline should not inherit insert-mode mappings")

local lspconfig = read(".config/nvim/lua/Sethy/plugins/lsp/lspconfig.lua")
local html_block = extract_lsp_block(lspconfig, "html")
local emmet_language_server_block = extract_lsp_block(lspconfig, "emmet_language_server")

assert_match(lspconfig, 'capabilities = require%("blink%.cmp"%)%.get_lsp_capabilities%(%)',
  "lspconfig should derive capabilities from blink.cmp")
assert_no_match(lspconfig, 'vim%.lsp%.completion%.enable',
  "lspconfig should not enable native LSP completion autotrigger")
assert_no_match(lspconfig, 'vim%.lsp%.config%("emmet_ls"',
  "lspconfig should not configure emmet_ls")
assert_no_match(lspconfig, 'vim%.lsp%.enable%("emmet_ls"%)',
  "lspconfig should not enable emmet_ls")
assert_match(lspconfig, 'vim%.lsp%.config%("svelte"', "lspconfig should configure the svelte language server")
assert_match(lspconfig, 'vim%.lsp%.enable%("svelte"%)', "lspconfig should enable the svelte language server")
assert_match(html_block, '"html"', "html LSP should support html files")
assert_match(html_block, '"templ"', "html LSP should support templ files")
assert_no_match(html_block, '"javascriptreact"', "html LSP should not support javascriptreact")
assert_no_match(html_block, '"typescriptreact"', "html LSP should not support typescriptreact")
assert_no_match(html_block, '"astro"', "html LSP should not support astro")
assert_no_match(html_block, '"svelte"', "html LSP should not support svelte")
assert_match(emmet_language_server_block, '"javascriptreact"',
  "emmet_language_server should support javascriptreact")
assert_match(emmet_language_server_block, '"typescriptreact"',
  "emmet_language_server should support typescriptreact")
assert_match(emmet_language_server_block, '"astro"',
  "emmet_language_server should support astro")
assert_match(emmet_language_server_block, '"svelte"',
  "emmet_language_server should support svelte")

local conform = read(".config/nvim/lua/Sethy/plugins/conform.lua")
assert_match(conform, 'astro = { "prettier" }', "astro should format with prettier")
assert_match(conform, 'svelte = { "prettier" }', "svelte should format with prettier")
assert_match(conform, "format_on_save", "web files should format on save")

local tailwind = read(".config/nvim/lua/Sethy/plugins/tailwind-tools.lua")
assert_match(tailwind, '"javascriptreact"', "tailwind colorizer should support javascriptreact")
assert_match(tailwind, '"typescriptreact"', "tailwind colorizer should support typescriptreact")
assert_match(tailwind, '"astro"', "tailwind colorizer should support astro")

local autopairs = read(".config/nvim/lua/Sethy/plugins/auto-pairs.lua")
assert_no_match(autopairs, '"hrsh7th/nvim%-cmp"', "autopairs should not depend on nvim-cmp")
assert_no_match(autopairs, 'completion%.cmp', "autopairs should not use cmp confirm hooks")

local noice = read(".config/nvim/lua/Sethy/plugins/noice.lua")
assert_match(noice, 'popupmenu = {', "noice should keep popupmenu configuration explicit")
assert_match(noice, 'enabled = false', "noice popupmenu should not expect the cmp backend")
assert_no_match(noice, 'backend = "cmp"', "noice should not depend on the cmp popupmenu backend")

print("nvim web support tests passed")
