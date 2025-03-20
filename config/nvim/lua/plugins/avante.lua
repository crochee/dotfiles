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
		provider = "kimi",
		vendors = {
			kimi = {
				__inherited_from = "openai",
				endpoint = "https://api.moonshot.cn/v1/",
				model = "moonshot-v1-32k", -- Choose model: "moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"
				api_key_name = "LLM_KEY",
				max_tokens = 4096,
				timeout = 30000,
				disable_tools = false,
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
