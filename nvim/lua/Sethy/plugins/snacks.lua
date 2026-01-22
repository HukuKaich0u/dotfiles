return {
	-- HACK: docs @ https://github.com/folke/snacks.nvim/blob/main/docs
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,
		opts = {
			quickfile = {
				enabled = true,
				exclude = { "latex" },
			},
			explorer = {
				enabled = true,
			},
			-- HACK: read picker docs @ https://github.com/folke/snakcs.nvim/blob/main/docs/picker.md
			picker = {
				enabled = true,
				matchers = {
					frecency = true,
					cwd_bonus = true,
				},
				formatters = {
					file = {
						filename_first = false,
						filename_only = false,
						icon_width = 2,
					},
				},
				layout = {
					preset = "telescope",
					cycle = false,
				},
				layouts = {
					select = {
						preview = false,
						layout = {
							backdrop = false,
							width = 0.6,
							min_width = 80,
							height = 0.4,
							min_height = 10,
							box = "vertical",
							border = "rounded",
							title = "{title}",
							title_pos = "center",
							-- { win = "input", height = 1, border = "bottom" },
							-- { win = "list", border = "none" },
							-- { win = "preview", title = "{preview}", width = 0.6, height = 0.4, border = "top" },
						},
					},
					telescope = {
						reverse = true, -- set to false for search bar to be on top
						layout = {
							box = "horizontal",
							backdrop = false,
							width = 0.95,
							height = 0.9,
							border = "none",
							{
								box = "vertical",
								{ win = "list", title = "results", title_pos = "center", border = "rounded" },
								{
									win = "input",
									height = 1,
									border = "rounded",
									title = "{title} {live} {flags}",
									title_pos = "center",
								},
							},
							{
								win = "preview",
								title = "{preview:preview}",
								width = 0.65,
								border = "rounded",
								title_pos = "center",
							},
						},
					},
					ivy = {
						layout = {
							box = "vertical",
							backdrop = false,
							width = 0,
							height = 0.4,
							position = "bottom",
							border = "top",
							title = "{title} {live} {flags}",
							title_pos = "left",
							{ win = "input", height = 1, border = "bottom" },
							{
								box = "horizontal",
								{ win = "list", border = "none" },
								{ win = "preview", title = "{preview}", width = 0.5, border = "left" },
							},
						},
					},
				},
			},
			image = {
				enabled = true,
				doc = {
					float = false,
					inline = true, -- if you want show image on cursor hover
					max_width = 50,
					wo = {
						wrap = true,
					},
					convert = {
						notify = true,
						command = "magick",
					},
					img_dirs = {
						"img",
						"images",
						"assets",
						"static",
						"public",
						"media",
						"attachments",
						"Archives/All-Vault-Images/",
						"~/Library",
						"~/Downloads",
					},
				},
			},
			dashboard = {
				enabled = true,
				sections = {
					{ section = "header" },
					{ section = "keys", gap = 1, padding = 1 },
					{
						section = "terminal",
						cmd = ("ascii-image-converter %q -C -c"):format(vim.fn.expand("~/Documents/profiles.jpeg")),
						pane = 2,
						indent = 4,
						height = 30,
					},
				},
			},
		},
		keys = {
			{
				"<leader>lg",
				function()
					require("snacks").lazygit()
				end,
				desc = "lazygit",
			},
			{
				"<leader>gl",
				function()
					require("snacks").lazygit.log()
				end,
				desc = "lazygit logs",
			},
			{
				"<leader>rn",
				function()
					require("snacks").rename.rename_file()
				end,
				desc = "fast rename current file",
			},
			{
				"<leader>db",
				function()
					require("snacks").bufdelete()
				end,
				desc = "delete or close buffer (confirm)",
			},

			-- snacks picker
			{
				"<leader>pf",
				function()
					require("snacks").picker.files()
				end,
				desc = "find files (snacks picker)",
			},
			{
				"<leader>pc",
				function()
					require("snacks").picker.files({ cwd = vim.fn.stdpath("config") })
				end,
				desc = "find config file",
			},
			{
				"<leader>ps",
				function()
					require("snacks").picker.grep()
				end,
				desc = "grep word",
			},
			{
				"<leader>pws",
				function()
					require("snacks").picker.grep_word()
				end,
				desc = "search visual selection or word",
				mode = { "n", "x" },
			},
			{
				"<leader>pk",
				function()
					require("snacks").picker.keymaps({ layout = "ivy" })
				end,
				desc = "search keymaps (snacks picker)",
			},

			{
				"<leader>gbr",
				function()
					require("snacks").picker.git_branches({ layout = "select" })
				end,
				desc = "pick and switch git branches",
			},
			{
				"<leader>th",
				function()
					require("snacks").picker.colorschemes({ layout = "ivy" })
				end,
				desc = "pick color schemes",
			},
			{
				"<leader>vh",
				function()
					require("snacks").picker.help()
				end,
				desc = "help pages",
			},
			{
				"<leader>ee",
				function()
					require("snacks").explorer()
				end,
				desc = "File Explorer",
			},
		},
	},
	{
		"folke/todo-comments.nvim",
		event = { "BufReadPre", "BufNewFile" },
		keys = {
			{
				"<leader>pt",
				function()
					require("snacks").picker.todo_comments()
				end,
				desc = "Todo",
			},
			{
				"<leader>pT",
				function()
					require("snacks").picker.todo_comments({ filter = { keywords = { "TODO", "FIX", "FIXME" } } })
				end,
				desc = "Todo/Fix/Fixme",
			},
		},
	},
}
