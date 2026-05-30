local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo_root .. "/nix/modules/home/assets/nvim")

local env = require("Sethy.core.env")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local function assert_truthy(value, message)
  if not value then
    error(message)
  end
end

assert_equal(env.path_exists("/definitely/not/here"), false, "path_exists should return false for missing paths")
assert_truthy(env.clipboard_available({
  executable = function(cmd)
    return cmd == "xclip"
  end,
}), "clipboard should be available when xclip exists")
assert_equal(env.clipboard_available({
  executable = function()
    return false
  end,
}), false, "clipboard should be unavailable without providers")
assert_truthy(env.supports_luarocks({
  directory_exists = function(path)
    return path:match("/%.luarocks/")
  end,
}), "luarocks support should be enabled when local rocks directories exist")
assert_equal(env.supports_luarocks({
  directory_exists = function()
    return false
  end,
}), false, "luarocks support should be disabled when rocks directories are missing")
do
  local old_path = package.path
  local old_cpath = package.cpath
  local old_supports = env.supports_luarocks
  local original_expand = vim.fn.expand

  env.supports_luarocks = function()
    return true
  end
  vim.fn.expand = function(value)
    if value == "$HOME" then
      return "/tmp/test-home"
    end
    return original_expand(value)
  end

  env.setup_luarocks()
  local path_after_first = package.path
  local cpath_after_first = package.cpath
  env.setup_luarocks()

  local init_pattern = "/tmp/test%-home/%.luarocks/share/lua/5%.1/%?/init%.lua"
  local lua_pattern = "/tmp/test%-home/%.luarocks/share/lua/5%.1/%?%.lua"
  local so_pattern = "/tmp/test%-home/%.luarocks/lib/lua/5%.1/%?%.so"

  assert_truthy(path_after_first:match(init_pattern),
    "setup_luarocks should append luarocks init path")
  assert_truthy(path_after_first:match(lua_pattern),
    "setup_luarocks should append luarocks lua path")
  assert_truthy(cpath_after_first:match(so_pattern),
    "setup_luarocks should append luarocks cpath")
  assert_equal(select(2, path_after_first:gsub(init_pattern, "")), 1,
    "setup_luarocks should append init path only once")
  assert_equal(select(2, path_after_first:gsub(lua_pattern, "")), 1,
    "setup_luarocks should append lua path only once")
  assert_equal(select(2, cpath_after_first:gsub(so_pattern, "")), 1,
    "setup_luarocks should append cpath only once")
  assert_equal(package.path, path_after_first,
    "setup_luarocks should be idempotent for package.path")
  assert_equal(package.cpath, cpath_after_first,
    "setup_luarocks should be idempotent for package.cpath")

  package.path = old_path
  package.cpath = old_cpath
  env.supports_luarocks = old_supports
  vim.fn.expand = original_expand
end
assert_equal(env.image_backend({
  executable = function()
    return false
  end,
}), nil, "image backend should be disabled without terminal support")
assert_equal(env.image_backend({
  executable = function(cmd)
    return cmd == "kitten"
  end,
}), "kitty", "image backend should use kitty when kitten is available")
assert_truthy(vim.tbl_contains(env.image_directories("/tmp/home", { is_mac = false }), "/tmp/home/Downloads"),
  "image directories should include cross-platform home downloads")
assert_equal(vim.tbl_contains(env.image_directories("/tmp/home", { is_mac = false }), "/tmp/home/Library"), false,
  "image directories should not include macOS-only library path by default")
assert_truthy(vim.tbl_contains(env.image_directories("/tmp/home", { is_mac = true }), "/tmp/home/Library"),
  "image directories should include macOS library path on macOS")

print("nvim env tests passed")
