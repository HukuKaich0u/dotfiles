return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local parsers = {
				-- data / config
				"json",
				"yaml",
				"toml",
				"ini",
				"nix",

				-- web
				"javascript",
				"typescript",
				"tsx",
				"html",
				"css",

				-- backend / systems
				"python",
				"go",
				"gomod",
				"gowork",
				"gosum",
				"java",
				"javadoc",
				"rust",
				"c",
				"cpp",
				-- infra
				"dockerfile",
				"terraform",
				"http",

				-- db
				"sql",
				"prisma",

				-- docs
				"markdown",
				"markdown_inline",

				-- tooling
				"bash",
				"lua",
				"vim",
				"vimdoc",
				"gitignore",
				"query",
				"regex",
				"make",
				"diff",
				"tmux",
			}

			local function highlight(bufnr)
				if vim.api.nvim_buf_is_loaded(bufnr) and vim.bo[bufnr].buftype == ""
					and vim.api.nvim_buf_line_count(bufnr) <= 20000 then
					pcall(vim.treesitter.start, bufnr)
				end
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("treesitter_enable", { clear = true }),
				pattern = "*",
				callback = function(event)
					highlight(event.buf)
				end,
			})
			-- install() is asynchronous and skips installed parsers. Re-attach open
			-- buffers when the first installation completes, without blocking startup.
			require("nvim-treesitter").install(parsers):await(function(err)
				vim.schedule(function()
					if err then
						vim.notify("Treesitter installation failed: " .. tostring(err), vim.log.levels.WARN)
						return
					end
					for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
						highlight(bufnr)
					end
				end)
			end)
		end,
	},
	-- NOTE: js, ts, jsx, tsx Auto Close Tags
	{
		"windwp/nvim-ts-autotag",
		ft = { "html", "xml", "javascript", "typescript", "javascriptreact", "typescriptreact", "svelte", "astro" },
		config = function()
			require("nvim-ts-autotag").setup({
				opts = {
					enable_close = true,
					enable_rename = true,
					enable_close_on_slash = false,
				},
			})
		end,
	},
}
