local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo_root .. "/nix/modules/home/assets/nvim")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local window = require("Sethy.core.window")

local function width(win)
  return vim.api.nvim_win_get_width(win)
end

local function height(win)
  return vim.api.nvim_win_get_height(win)
end

-- 左右 2 分割: h は境界を左へ、l は境界を右へ動かす
-- (:vsplit は splitright の値で新しい窓の位置が変わるので wincmd で左右を選ぶ)
vim.cmd("silent! only")
vim.cmd("vsplit")
vim.cmd("wincmd =")
vim.cmd("wincmd h")
local left = vim.api.nvim_get_current_win()
vim.cmd("wincmd l")
local right = vim.api.nvim_get_current_win()
assert_equal(left ~= right, true, "there should be two windows side by side")

vim.api.nvim_set_current_win(left)
local base = width(left)
window.move_border("l", 5)
assert_equal(width(left), base + 5, "l in the left window should move the border right (left grows)")
window.move_border("h", 5)
assert_equal(width(left), base, "h in the left window should move the border left (left shrinks)")

vim.api.nvim_set_current_win(right)
base = width(right)
window.move_border("h", 5)
assert_equal(width(right), base + 5, "h in the right-edge window should move the border left (right grows)")
window.move_border("l", 5)
assert_equal(width(right), base, "l in the right-edge window should move the border right (right shrinks)")

-- 上下 2 分割: k は境界を上へ、j は境界を下へ動かす
vim.cmd("silent! only")
vim.cmd("split")
vim.cmd("wincmd =")
vim.cmd("wincmd k")
local top = vim.api.nvim_get_current_win()
vim.cmd("wincmd j")
local bottom = vim.api.nvim_get_current_win()
assert_equal(top ~= bottom, true, "there should be two windows stacked")

vim.api.nvim_set_current_win(top)
base = height(top)
window.move_border("j", 3)
assert_equal(height(top), base + 3, "j in the top window should move the border down (top grows)")
window.move_border("k", 3)
assert_equal(height(top), base, "k in the top window should move the border up (top shrinks)")

vim.api.nvim_set_current_win(bottom)
base = height(bottom)
window.move_border("k", 3)
assert_equal(height(bottom), base + 3, "k in the bottom-edge window should move the border up (bottom grows)")
window.move_border("j", 3)
assert_equal(height(bottom), base, "j in the bottom-edge window should move the border down (bottom shrinks)")

-- 左右 3 分割の真ん中: 隣が両側にあるときは右側の境界を動かす（tmux と同じ）
vim.cmd("silent! only")
vim.cmd("vsplit")
vim.cmd("vsplit")
vim.cmd("wincmd =")
vim.cmd("wincmd t")
vim.cmd("wincmd l")
local middle = vim.api.nvim_get_current_win()
assert_equal(vim.fn.winnr(), 2, "the middle window should be the second one")
base = width(middle)
window.move_border("l", 5)
assert_equal(width(middle), base + 5, "l in the middle window should move its right border right")
window.move_border("h", 5)
assert_equal(width(middle), base, "h in the middle window should move its right border left")

-- 境界のない軸では何もしない: 左右分割だけのとき j/k は高さを変えない
vim.cmd("silent! only")
vim.cmd("vsplit")
local solo_height = height(0)
window.move_border("j", 3)
assert_equal(height(0), solo_height, "j with no window above or below should not change the height")
window.move_border("k", 3)
assert_equal(height(0), solo_height, "k with no window above or below should not change the height")
vim.cmd("silent! only")
local solo_width = width(0)
window.move_border("l", 5)
assert_equal(width(0), solo_width, "l in a single window should not change the width")

-- 不正な向きはエラーにする
local ok = pcall(window.move_border, "x", 5)
assert_equal(ok, false, "an unknown direction should raise an error")
