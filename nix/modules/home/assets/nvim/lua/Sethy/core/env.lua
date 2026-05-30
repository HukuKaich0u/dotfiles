local M = {}

local function append_unique_package_entry(field, entry)
    if package[field]:find(entry, 1, true) then
        return
    end

    package[field] = package[field] .. ";" .. entry
end

local function default_directory_exists(path)
    return vim.fn.isdirectory(vim.fn.expand(path)) == 1
end

local function default_file_exists(path)
    return vim.fn.filereadable(vim.fn.expand(path)) == 1
end

local function default_executable(cmd)
    return vim.fn.executable(cmd) == 1
end

function M.path_exists(path)
    return vim.uv.fs_stat(path) ~= nil
end

function M.clipboard_available(deps)
    deps = deps or {}
    local executable = deps.executable or default_executable

    return executable("pbcopy")
        or executable("wl-copy")
        or executable("xclip")
        or executable("xsel")
        or executable("tmux")
end

function M.supports_luarocks(deps)
    deps = deps or {}
    local directory_exists = deps.directory_exists or default_directory_exists

    return directory_exists("~/.luarocks/share/lua/5.1")
        and directory_exists("~/.luarocks/lib/lua/5.1")
end

function M.setup_luarocks()
    if not M.supports_luarocks() then
        return
    end

    local home = vim.fn.expand("$HOME")
    append_unique_package_entry("path", home .. "/.luarocks/share/lua/5.1/?/init.lua")
    append_unique_package_entry("path", home .. "/.luarocks/share/lua/5.1/?.lua")
    append_unique_package_entry("cpath", home .. "/.luarocks/lib/lua/5.1/?.so")
end

function M.image_backend(deps)
    deps = deps or {}
    local executable = deps.executable or default_executable

    if executable("kitten") then
        return "kitty"
    end

    return nil
end

function M.image_support_enabled(deps)
    deps = deps or {}
    local executable = deps.executable or default_executable
    local file_exists = deps.file_exists or default_file_exists

    return M.image_backend(deps) ~= nil
        and executable("magick")
        and (file_exists("~/.luarocks/lib/lua/5.1/magick.so") or file_exists("~/.luarocks/share/lua/5.1/magick/init.lua"))
end

function M.paste_image_enabled(deps)
    deps = deps or {}
    local executable = deps.executable or default_executable

    return executable("pngpaste")
        or executable("wl-paste")
        or executable("xclip")
        or executable("xsel")
end

function M.image_directories(home, deps)
    home = home or vim.fn.expand("~")
    deps = deps or {}
    local is_mac = deps.is_mac
    if is_mac == nil then
        is_mac = vim.fn.has("macunix") == 1
    end

    local dirs = {
        "img",
        "images",
        "assets",
        "static",
        "public",
        "media",
        "attachments",
        "Archives/All-Vault-Images/",
        home .. "/Downloads",
    }

    if is_mac then
        table.insert(dirs, home .. "/Library")
    end

    return dirs
end

function M.dashboard_image_command(home)
    home = home or vim.fn.expand("~")
    local image_path = home .. "/Documents/profiles.jpeg"

    if not M.path_exists(image_path) or not default_executable("ascii-image-converter") then
        return nil
    end

    return ("ascii-image-converter %q -C -c"):format(image_path)
end

return M
