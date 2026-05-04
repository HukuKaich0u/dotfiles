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

local leetcode = read(".config/nvim/lua/Sethy/plugins/leetcode.lua")
assert_match(leetcode, '"kawre/leetcode%.nvim"', "leetcode config should install leetcode.nvim")
assert_match(leetcode, 'cmd = "Leet"', "leetcode config should lazy-load on :Leet")
assert_match(leetcode, 'lang = "rust"', "leetcode config should default to Rust")
assert_match(leetcode, 'enabled = false', "leetcode config should keep leetcode.cn disabled")
assert_match(leetcode, 'non_standalone = true', "leetcode config should support existing sessions")
assert_no_match(leetcode, "<leader>l", "leetcode config should not define custom leader-l keymaps")

print("nvim leetcode tests passed")
