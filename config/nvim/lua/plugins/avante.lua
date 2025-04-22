local M = {
	"yetone/avante.nvim",
	event = "VeryLazy",
	tag = "v0.0.23",
	build = "make",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-telescope/telescope.nvim", -- Optional: for file_selector provider telescope
		"nvim-tree/nvim-web-devicons", -- Optional: or echasnovski/mini.icons
		{
			"HakonHarnes/img-clip.nvim", -- Optional: support for image pasting
			event = "VeryLazy",
			opts = {
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					use_absolute_path = true, -- Required for Windows users
				},
			},
		},
		{
			"MeanderingProgrammer/render-markdown.nvim", -- Optional: for markdown rendering
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
}

--- Configure Avante
function M.config()
	require("avante").setup({
		provider = "ollama",
		vendors = {
			ollama = {
				__inherited_from = "openai",
				api_key_name = "",
				endpoint = "http://127.0.0.1:11434/v1",
				model = "qwen2.5-coder:1.5b",
				disable_tools = true, -- Open-source models often do not support tools.
			},
		},
		file_selector = {
			provider = "telescope",
		},
		behaviour = {
			-- auto_apply_diff_after_generation = true,
			enable_cursor_planning_mode = true, -- Enable Cursor Planning Mode
		},
	})
end

return M
