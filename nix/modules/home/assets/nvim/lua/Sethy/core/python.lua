local M = {}

function M.interpreter(root_dir)
    -- An activated environment is an explicit choice; otherwise use the project's .venv.
    local environments = {}
    for _, path in ipairs({
        vim.env.VIRTUAL_ENV or "",
        root_dir and (root_dir .. "/.venv") or "",
        vim.env.CONDA_PREFIX or "",
    }) do
        if path ~= "" then
            table.insert(environments, path)
        end
    end
    for _, path in ipairs(environments) do
        local python = path .. "/bin/python"
        if vim.fn.executable(python) == 1 then
            return python
        end
    end
    -- Let Pyright resolve its configured venv or the default interpreter.
end

function M.before_init(_, config)
    config.settings = config.settings or {}
    config.settings.python = config.settings.python or {}
    if not config.settings.python.pythonPath then
        config.settings.python.pythonPath = M.interpreter(config.root_dir)
    end
end

return M
