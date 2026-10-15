-- 分割ウィンドウのサイズ変更を、tmux の `prefix s` → h/j/k/l 連打の
-- key-table と同じ操作感にする。<leader>sr でモードに入り、h/j/k/l で
-- 境界を動かし、q / Esc / Enter で抜ける。
-- color = "red" なので、それ以外のキーは通常どおり実行されてモードを抜ける。
return {
    "nvimtools/hydra.nvim",
    keys = {
        { "<leader>sr", desc = "Resize mode" },
    },
    config = function()
        local Hydra = require("hydra")
        local window = require("Sethy.core.window")

        local step = { h = 5, l = 5, j = 3, k = 3 }

        local function move_border(direction)
            return function()
                window.move_border(direction, step[direction])
            end
        end

        Hydra({
            name = "Resize",
            mode = "n",
            body = "<leader>sr",
            config = {
                color = "red",
                invoke_on_body = true,
                hint = {
                    type = "window",
                    position = "bottom",
                    float_opts = { border = "rounded" },
                },
            },
            hint = " _h_ _j_ _k_ _l_: 境界を移動   _q_ / _<Esc>_ / _<CR>_: 終了 ",
            heads = {
                { "h", move_border("h") },
                { "j", move_border("j") },
                { "k", move_border("k") },
                { "l", move_border("l") },
                { "q", nil, { exit = true } },
                { "<Esc>", nil, { exit = true } },
                { "<CR>", nil, { exit = true } },
            },
        })
    end,
}
