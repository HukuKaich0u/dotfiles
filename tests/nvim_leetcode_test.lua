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

local leetcode = read("nix/home-manager/nvim/lua/Sethy/plugins/leetcode.lua")
assert_match(leetcode, '"kawre/leetcode%.nvim"', "leetcode config should install leetcode.nvim")
assert_match(leetcode, 'cmd = "Leet"', "leetcode config should lazy-load on :Leet")
assert_match(leetcode, 'lang = "rust"', "leetcode config should default to Rust")
assert_match(leetcode, 'enabled = false', "leetcode config should keep leetcode.cn disabled")
assert_match(leetcode, 'non_standalone = true', "leetcode config should support existing sessions")
assert_match(
  leetcode,
  'home = vim%.fn%.expand%("~/Documents/repos/personal/leetcode/leetcodenvim"%)',
  "leetcode config should store workspace files under the dedicated leetcodenvim directory"
)
assert_match(leetcode, 'description_ratio = 0%.45', "leetcode layout should keep the 45:55 target ratio")
assert_match(leetcode, 'code_min_width = 80', "leetcode layout should preserve minimum code width")
assert_match(leetcode, 'width = current_description_width%(%),', "leetcode description pane should use dynamic width")
assert_match(leetcode, 'VimResized', "leetcode layout should react to editor resizes")
assert_match(leetcode, 'nvim_win_set_width', "leetcode layout should resize the description split directly")
assert_no_match(leetcode, "<leader>l", "leetcode config should not define custom leader-l keymaps")

print("nvim leetcode tests passed")
