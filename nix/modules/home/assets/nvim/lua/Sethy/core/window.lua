-- 分割ウィンドウの境界を動かす。
--
-- `:resize -N` / `:vertical resize -N` は「今のウィンドウを縮める」なので、
-- 右端・下端のウィンドウでは境界が押した向きと逆に動いて見える。
-- tmux の `resize-pane -L/-R/-U/-D` と同じく、端のウィンドウでは符号を
-- 反転して、h/j/k/l がいつも「その向きに境界を動かす」ようにする。
local M = {}

-- edge: その向きに隣がないかを winnr() で調べるための方向
-- back: edge の反対側。両側に隣がなければその軸には境界がない
-- forward: 境界を動かす向きが、ウィンドウが大きくなる向きと同じか
local axis = {
    h = { vertical = true, forward = false, edge = "l", back = "h" },
    l = { vertical = true, forward = true, edge = "l", back = "h" },
    k = { vertical = false, forward = false, edge = "j", back = "k" },
    j = { vertical = false, forward = true, edge = "j", back = "k" },
}

---@param direction "h"|"j"|"k"|"l" 境界を動かす向き
---@param amount integer 動かす量（h/l は桁数、j/k は行数）
function M.move_border(direction, amount)
    local spec = axis[direction]
    if not spec then
        error(("unknown direction: %s"):format(tostring(direction)))
    end

    -- 隣がない向きでは winnr("l") などが自分の番号を返す
    local current = vim.fn.winnr()
    local at_far_edge = vim.fn.winnr(spec.edge) == current
    if at_far_edge and vim.fn.winnr(spec.back) == current then
        -- その軸に境界がない。唯一の行で :resize すると
        -- コマンドライン領域が広がるだけなので何もしない
        return
    end
    local grow = spec.forward ~= at_far_edge
    local command = spec.vertical and "vertical resize" or "resize"
    vim.cmd(("%s %s%d"):format(command, grow and "+" or "-", amount))
end

-- tmux の prefix z (resize-pane -Z) 相当。今のウィンドウだけを新しい tab に
-- 開いて画面いっぱいに表示し、もう一度呼ぶと tab を閉じて元のレイアウトに
-- 戻る。ズーム中に動かしたカーソル位置や開き直した buffer は、戻るときに
-- 元のウィンドウへ引き継ぐ。
function M.toggle_zoom()
    local origin = vim.t.sethy_zoom_origin
    if origin then
        local buf = vim.api.nvim_get_current_buf()
        local view = vim.fn.winsaveview()
        if #vim.api.nvim_list_tabpages() > 1 then
            vim.cmd("tabclose")
        else
            -- 元の tab が閉じられていて戻り先がない
            vim.t.sethy_zoom_origin = nil
        end
        if vim.api.nvim_win_is_valid(origin) then
            vim.api.nvim_set_current_win(origin)
            if vim.api.nvim_win_get_buf(origin) ~= buf then
                vim.api.nvim_win_set_buf(origin, buf)
            end
            vim.fn.winrestview(view)
        end
        return
    end

    local windows = vim.tbl_filter(function(win)
        return vim.api.nvim_win_get_config(win).relative == ""
    end, vim.api.nvim_tabpage_list_wins(0))
    if #windows < 2 then
        return -- 分割がなければズームするものがない
    end
    local current = vim.api.nvim_get_current_win()
    vim.cmd("tab split")
    vim.t.sethy_zoom_origin = current
end

return M
