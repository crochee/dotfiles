return {
	"nvim-telescope/telescope.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	cmd = "Telescope",
	keys = {
		{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
		{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live grep" },
		{ "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document symbols" },
		{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
		{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help tags" },
		{ "<leader>fc", "<cmd>Telescope command_history<cr>", desc = "Command history" },
	},
	opts = {
		defaults = {
			prompt_prefix = "🔍 ",
			layout_strategy = "vertical",
			vimgrep_arguments = {
				"rg",
				"--color=never",
				"--no-heading",
				"--with-filename",
				"--line-number",
				"--column",
				"--smart-case",
				"--vimgrep",
				"--multiline",
			},
			mappings = {
				i = {
					["<C-j>"] = "move_selection_next",
					["<C-k>"] = "move_selection_previous",
					["<Down>"] = "cycle_history_next",
					["<Up>"] = "cycle_history_prev",
					["<C-c>"] = "close",
					["<C-u>"] = "preview_scrolling_up",
					["<C-d>"] = "preview_scrolling_down",
				},
			},
		},
	},
}
