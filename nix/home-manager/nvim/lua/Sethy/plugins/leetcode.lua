local description_ratio = 0.45
local description_min_width = 45
local description_max_width = 110
local code_min_width = 80
local resize_group = vim.api.nvim_create_augroup("sethy_leetcode_dynamic_layout", { clear = true })
local resize_autocmd_registered = false

local function clamp(value, min_value, max_value)
    return math.max(min_value, math.min(value, max_value))
end

local function current_description_width()
    local total_columns = vim.o.columns
    local preferred_width = math.floor((total_columns * description_ratio) + 0.5)
    local max_width_for_code = total_columns - code_min_width
    local upper_bound = math.min(description_max_width, max_width_for_code)

    if upper_bound >= description_min_width then
        return clamp(preferred_width, description_min_width, upper_bound)
    end

    return clamp(preferred_width, 20, math.max(20, total_columns - 1))
end

local function resize_question_layout(question)
    local description = question and question.description
    if not description or not description.winid or not vim.api.nvim_win_is_valid(description.winid) then
        return
    end

    vim.api.nvim_win_set_width(description.winid, current_description_width())
end

local function resize_all_question_layouts()
    for _, question in ipairs(_Lc_state.questions or {}) do
        resize_question_layout(question)
    end
end

local function ensure_resize_autocmd()
    if resize_autocmd_registered then
        return
    end

    vim.api.nvim_create_autocmd("VimResized", {
        group = resize_group,
        callback = resize_all_question_layouts,
    })

    resize_autocmd_registered = true
end

return {
    "kawre/leetcode.nvim",
    cmd = "Leet",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
    },
    opts = {
        lang = "rust",
        cn = {
            enabled = false,
        },
        storage = {
            home = vim.fn.expand("~/Documents/repos/personal/leetcode/leetcodenvim"),
        },
        plugins = {
            non_standalone = true,
        },
        picker = {
            provider = "snacks-picker",
        },
        description = {
            width = current_description_width(),
        },
        hooks = {
            enter = {
                ensure_resize_autocmd,
            },
            question_enter = {
                function(question)
                    vim.schedule(function()
                        resize_question_layout(question)
                    end)
                end,
            },
        },
    },
}
