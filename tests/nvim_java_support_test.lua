local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local config_root = repo_root .. "/nix/modules/home/assets/nvim"
vim.opt.runtimepath:prepend(config_root)
local java = require("Sethy.core.java")
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp, "p")
tmp = vim.uv.fs_realpath(tmp)

local function file(path, content)
  vim.fn.mkdir(vim.fs.dirname(tmp .. "/" .. path), "p")
  vim.fn.writefile({ content or "" }, tmp .. "/" .. path)
  return tmp .. "/" .. path
end
local function buffer(path)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_name(bufnr, path)
  return bufnr
end
local ok, err = pcall(function()
  file("gradle/settings.gradle.kts")
  file("gradle/module/build.gradle.kts")
  local child = buffer(file("gradle/module/src/Example.java"))
  assert(java.root(child) == tmp .. "/gradle", "Gradle modules must share the workspace root")

  file("maven/mvnw")
  file("maven/pom.xml")
  file("maven/module/pom.xml")
  local module = buffer(file("maven/module/src/Main.java"))
  assert(java.root(module) == tmp .. "/maven", "Maven modules must share the wrapper root")

  local single = buffer(file("standalone/Hello.java"))
  assert(java.root(single) == tmp .. "/standalone", "Standalone Java files need a directory root")
  assert(
    java.workspace(tmp .. "/one/app") ~= java.workspace(tmp .. "/two/app"),
    "Same project names must not share indexes"
  )
  assert(
    java.workspace(tmp .. "/a_b/c") ~= java.workspace(tmp .. "/a/b_c"),
    "Path separators must not cause index collisions"
  )
  assert(java.workspace(tmp .. "/gradle") == java.workspace(tmp .. "/gradle/."), "Equivalent paths must share indexes")

  local started
  package.loaded["blink.cmp"] = {
    get_lsp_capabilities = function()
      return { completion = true }
    end,
  }
  package.loaded["jdtls"] = {
    start_or_attach = function(config)
      started = config
    end,
  }
  local executable = vim.fn.executable
  vim.fn.executable = function(cmd)
    return cmd == "jdtls" and 1 or executable(cmd)
  end
  vim.api.nvim_set_current_buf(child)
  dofile(config_root .. "/after/ftplugin/java.lua")
  vim.fn.executable = executable
  assert(started and started.root_dir == tmp .. "/gradle", "ftplugin must pass the workspace root to jdtls")
  assert(started.cmd[#started.cmd] == java.workspace(started.root_dir), "jdtls must persist its per-project index")
  assert(started.capabilities.completion, "Java completion capabilities must reach the client")
end)

vim.fn.delete(tmp, "rf")
if not ok then
  error(err)
end
print("nvim java support tests passed")
