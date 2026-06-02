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

local mason = read("nix/modules/home/assets/nvim/lua/Sethy/plugins/lsp/mason.lua")
assert_match(mason, '"jdtls"', "mason should install jdtls for Java")

local java_ftplugin = read("nix/modules/home/assets/nvim/after/ftplugin/java.lua")
assert_match(java_ftplugin, "vim%.lsp%.start", "java ftplugin should start jdtls with the built-in LSP client")
assert_match(java_ftplugin, "capabilities = require%(\"blink%.cmp\"%)%.get_lsp_capabilities%(%)",
  "jdtls should use shared completion capabilities")
assert_match(java_ftplugin, "%-%-jvm%-arg=%-Xmx2g", "jdtls should cap heap usage")
assert_match(java_ftplugin, "jdtls%-workspaces", "jdtls should isolate workspace data under Neovim state")
assert_match(java_ftplugin, "gsub", "jdtls workspace names should avoid same-project-name collisions")
assert_match(java_ftplugin, "root_dir", "jdtls should detect project roots")
assert_match(java_ftplugin, "reuse_client", "jdtls should reuse the project client across Java buffers")

local conform = read("nix/modules/home/assets/nvim/lua/Sethy/plugins/conform.lua")
assert_match(conform, "java = true", "Java should format on save through jdtls")

local docs = read("nix/modules/home/assets/nvim/docs/plugins-guide.md")
assert_match(docs, "| Java | jdtls %(LSP%) |", "plugin guide should document Java formatting")

do
  local original_lsp_start = vim.lsp.start
  local original_blink = package.preload["blink.cmp"]
  local started_config

  package.preload["blink.cmp"] = function()
    return {
      get_lsp_capabilities = function()
        return { textDocument = { completion = {} } }
      end,
    }
  end

  vim.lsp.start = function(config)
    started_config = config
    return 1
  end

  vim.opt.updatecount = 0
  vim.cmd("enew")
  vim.api.nvim_buf_set_name(0, repo_root .. "/Example.java")
  local ok, err = pcall(assert(loadfile(repo_root .. "/nix/modules/home/assets/nvim/after/ftplugin/java.lua")))

  vim.lsp.start = original_lsp_start
  package.preload["blink.cmp"] = original_blink

  if not ok then
    error(err)
  end
  if not started_config then
    error("java ftplugin should start jdtls when a project root is available")
  end
  if started_config.name ~= "jdtls" then
    error("java ftplugin should start the jdtls client")
  end
end

print("nvim java support tests passed")
