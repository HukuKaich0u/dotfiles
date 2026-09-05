local env = require("Sethy.core.env")

local dashboard_sections = {
	{ section = "header" },
	{ section = "keys", gap = 1, padding = 1 },
}

local dashboard_image_command = env.dashboard_image_command()
if dashboard_image_command then
	table.insert(dashboard_sections, {
		section = "terminal",
		cmd = dashboard_image_command,
		pane = 2,
		indent = 4,
		height = 30,
	})
end

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
				hidden = true,
				ignored = true,
			},
			-- HACK: read picker docs @ https://github.com/folke/snakcs.nvim/blob/main/docs/picker.md
				picker = {
					enabled = true,
					sources = {
						files = {
							hidden = true,
							ignored = true,
						},
						grep = {
							hidden = true,
							ignored = true,
						},
						explorer = {
							hidden = true,
							ignored = true,
						},
					},
					win = {
						input = {
							keys = {
								["H"] = { "toggle_hidden", mode = { "i", "n" } },
								["I"] = { "toggle_ignored", mode = { "i", "n" } },
							},
						},
						list = {
							keys = {
								["H"] = "toggle_hidden",
								["I"] = "toggle_ignored",
							},
						},
					},
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
					enabled = false,
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
						unpack(env.image_directories()),
						},
					},
				},
				dashboard = {
					enabled = true,
					sections = dashboard_sections,
			},
			lazygit = {
				theme = {
					[241] = { fg = "Special" },
					activeBorderColor = { fg = "FloatTitle", bold = true },
					cherryPickedCommitBgColor = { fg = "Identifier" },
					cherryPickedCommitFgColor = { fg = "Function" },
					defaultFgColor = { fg = "Normal" },
					inactiveBorderColor = { fg = "FloatBorder" },
					optionsTextColor = { fg = "Function" },
					searchingActiveBorderColor = { fg = "FloatTitle", bold = true },
					selectedLineBgColor = { bg = "Visual" },
					unstagedChangesColor = { fg = "DiagnosticError" },
				},
			},
		},
		keys = {
			{
				"<leader>gg",
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
				"<leader>cR",
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
				"<leader>ts",
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
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
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
