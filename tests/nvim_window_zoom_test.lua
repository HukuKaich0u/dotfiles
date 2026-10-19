local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(repo_root .. "/nix/modules/home/assets/nvim")

local function assert_equal(actual, expected, message)
  if actual ~= expected then
    error(("%s\nexpected: %s\nactual: %s"):format(message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local window = require("Sethy.core.window")

local function tabs()
  return #vim.api.nvim_list_tabpages()
end

local function windows()
  return #vim.tbl_filter(function(win)
    return vim.api.nvim_win_get_config(win).relative == ""
  end, vim.api.nvim_tabpage_list_wins(0))
end

local lines = {}
for i = 1, 100 do
  lines[i] = "line " .. i
end
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
local buf = vim.api.nvim_get_current_buf()

-- 分割がなければ何もしない
vim.cmd("silent! only")
window.toggle_zoom()
assert_equal(tabs(), 1, "zoom with a single window should do nothing")

-- 分割があれば、今のウィンドウだけを新しい tab に開く
vim.cmd("vsplit | split | wincmd =")
local origin = vim.api.nvim_get_current_win()
vim.api.nvim_win_set_cursor(origin, { 10, 0 })
local origin_width = vim.api.nvim_win_get_width(origin)
assert_equal(origin_width < vim.o.columns, true, "the origin window should be narrower than the editor")

window.toggle_zoom()
assert_equal(tabs(), 2, "zoom should open a new tab")
assert_equal(windows(), 1, "the zoom tab should hold only one window")
assert_equal(vim.api.nvim_get_current_buf(), buf, "the zoom tab should show the same buffer")
assert_equal(vim.api.nvim_win_get_width(0), vim.o.columns, "the zoomed window should use the full width")
assert_equal(vim.api.nvim_win_get_cursor(0)[1], 10, "the cursor position should carry into the zoom")

-- 戻るとき、ズーム中に動かしたカーソル位置を元のウィンドウへ引き継ぐ
vim.api.nvim_win_set_cursor(0, { 50, 0 })
window.toggle_zoom()
assert_equal(tabs(), 1, "unzoom should close the zoom tab")
assert_equal(vim.api.nvim_get_current_win(), origin, "unzoom should return to the original window")
assert_equal(windows(), 3, "the original layout should be intact")
assert_equal(vim.api.nvim_win_get_width(origin), origin_width, "the original window size should be intact")
assert_equal(vim.api.nvim_win_get_cursor(origin)[1], 50, "the cursor moved while zoomed should carry back")

-- ズーム中に別の buffer を開いたら、それも元のウィンドウへ引き継ぐ
window.toggle_zoom()
assert_equal(tabs(), 2, "zoom should work again from the original tab")
vim.cmd("enew")
local other = vim.api.nvim_get_current_buf()
assert_equal(other ~= buf, true, "enew should create another buffer")
window.toggle_zoom()
assert_equal(tabs(), 1, "unzoom should close the zoom tab again")
assert_equal(vim.api.nvim_get_current_win(), origin, "unzoom should return to the original window again")
assert_equal(vim.api.nvim_win_get_buf(origin), other, "a buffer opened while zoomed should stay in the original window")

-- 元の tab がなくなっていても、ズーム状態は解除できる
vim.api.nvim_win_set_buf(origin, buf)
window.toggle_zoom()
assert_equal(tabs(), 2, "zoom should open a new tab once more")
local zoom_tab = vim.api.nvim_get_current_tabpage()
for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
  if tab ~= zoom_tab then
    vim.api.nvim_set_current_tabpage(tab)
    vim.cmd("tabclose")
  end
end
vim.api.nvim_set_current_tabpage(zoom_tab)
assert_equal(tabs(), 1, "only the zoom tab should remain")
window.toggle_zoom()
assert_equal(tabs(), 1, "unzoom with no origin tab should not fail")
assert_equal(vim.t.sethy_zoom_origin, nil, "the zoom marker should be cleared")
