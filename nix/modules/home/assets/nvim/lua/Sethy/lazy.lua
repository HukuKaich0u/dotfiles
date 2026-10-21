local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local config_root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")
local seed = config_root .. "/lazy-lock.json"
local lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json"
local lock = vim.json.decode(table.concat(vim.fn.readfile(seed), "\n"))
-- Home Manager seeds this on switch; also support the first direct config run.
if vim.fn.filereadable(lockfile) == 0 then
	vim.fn.mkdir(vim.fn.fnamemodify(lockfile, ":h"), "p")
	vim.fn.writefile(vim.fn.readfile(seed), lockfile)
end
if not vim.loop.fs_stat(lazypath) then
	local output = vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--no-checkout",
		lazypath,
	})
	if vim.v.shell_error ~= 0 then
		error("lazy.nvim clone failed: " .. output)
	end
	output = vim.fn.system({ "git", "-C", lazypath, "checkout", lock["lazy.nvim"].commit })
	if vim.v.shell_error ~= 0 then
		vim.fn.delete(lazypath, "rf")
		error("lazy.nvim checkout failed: " .. output)
	end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	{ import = "Sethy.plugins" },
	{ import = "Sethy.plugins.lsp" },
}, {
	lockfile = lockfile,
	checker = {
		enabled = false,
		notify = false,
	},
	change_detection = {
		notify = false,
	},
})
