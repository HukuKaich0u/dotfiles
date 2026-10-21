local repo_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local source = repo_root .. "/nix/modules/home/assets/nvim"
local tmp = vim.fn.tempname()
vim.fn.mkdir(tmp .. "/config/lua/Sethy", "p")
vim.fn.writefile(vim.fn.readfile(source .. "/lazy-lock.json"), tmp .. "/config/lazy-lock.json")
vim.fn.writefile(vim.fn.readfile(source .. "/lua/Sethy/lazy.lua"), tmp .. "/config/lua/Sethy/lazy.lua")
local original_stdpath, original_system = vim.fn.stdpath, vim.fn.system
local original_lazy = package.loaded["lazy"]
local configured, calls = nil, {}
local ok, err = pcall(function()
	local lock = vim.json.decode(table.concat(vim.fn.readfile(source .. "/lazy-lock.json"), "\n"))
	for name, entry in pairs(lock) do
		assert(entry.commit:match("^%x+$") and #entry.commit == 40, name .. " must have an exact Git revision")
	end
	vim.fn.stdpath = function(kind)
		return tmp .. "/" .. kind
	end
	vim.fn.system = function(args)
		table.insert(calls, args)
		return ""
	end
	package.loaded["lazy"] = {
		setup = function(_, options)
			configured = options
		end,
	}
	dofile(tmp .. "/config/lua/Sethy/lazy.lua")
	assert(vim.fn.filereadable(tmp .. "/state/lazy-lock.json") == 1, "A fresh machine must receive the shared lock")
	assert(configured.lockfile == tmp .. "/state/lazy-lock.json", "Lazy must write outside the Nix store")
	assert(not configured.checker.enabled, "Updates must be explicit")
	assert(
		calls[2][4] == "checkout" and calls[2][5] == lock["lazy.nvim"].commit,
		"Bootstrap must use the locked Lazy revision"
	)
	assert(vim.deep_equal(vim.json.decode(table.concat(vim.fn.readfile(configured.lockfile), "\n")), lock))
end)
vim.fn.stdpath, vim.fn.system = original_stdpath, original_system
package.loaded["lazy"] = original_lazy
vim.fn.delete(tmp, "rf")
if not ok then
	error(err)
end
print("Neovim plugin lock tests passed")
