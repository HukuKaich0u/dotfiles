local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo_root .. "/nix/home-manager/nvim")

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
