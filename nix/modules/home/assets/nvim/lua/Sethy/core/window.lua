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

return M
