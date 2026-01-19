return {
	-- Paste images from clipboard (requires: brew install pngpaste)
	{
		"HakonHarnes/img-clip.nvim",
		event = "VeryLazy",
		keys = {
			{ "<leader>pi", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
		},
		opts = {
			default = {
				insert_mode_after_paste = true,
				url_encode_path = true,
				template = "![$CURSOR]($FILE_PATH)",
				use_cursor_in_template = true,

				prompt_for_file_name = true,
				show_dir_path_in_prompt = true,

				use_absolute_path = false,
				relative_to_current_file = true,

				embed_image_as_base64 = false,
				max_base64_size = 10,

				dir_path = "assets",

				drag_and_drop = {
					enabled = true,
					insert_mode = true,
					copy_images = true,
					download_images = true,
				},
			},
		},
	},

	-- Display images in Neovim (requires: luarocks --local --lua-version=5.1 install magick)
	{
		"3rd/image.nvim",
		ft = { "markdown", "norg", "html", "css" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
		},
		opts = {
			backend = "kitty", -- WezTerm supports kitty graphics protocol
			processor = "magick_rock",
			integrations = {
				markdown = {
					enabled = true,
					clear_in_insert_mode = false,
					download_remote_images = true,
					only_render_image_at_cursor = false,
					filetypes = { "markdown", "vimwiki" },
				},
			},
			max_width = nil,
			max_height = nil,
			max_width_window_percentage = nil,
			max_height_window_percentage = 50,
			window_overlap_clear_enabled = false,
			window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
			editor_only_render_when_focused = false,
			tmux_show_only_in_active_window = false,
			hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
		},
	},
}
