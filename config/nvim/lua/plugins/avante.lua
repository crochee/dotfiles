return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	-- enabled = false,
	version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
	opts = {
		provider = "deepseek",
		providers = {
			deepseek = {
				__inherited_from = "openai",
				api_key_name = "DEEPSEEK_API_KEY",
				endpoint = "https://api.deepseek.com",
				model = "deepseek-coder",
			},
		},
		auto_suggestions_provider = "deepseek",
		file_selector = {
			provider = "telescope",
		},
		selector = {
			exclude_auto_select = { "NvimTree" },
		},
        behaviour = {
			-- auto_apply_diff_after_generation = true,
			enable_cursor_planning_mode = true, -- Enable Cursor Planning Mode
		},
	},
	-- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
	build = "make",
	-- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- for windows
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"nvim-telescope/telescope.nvim", -- for file_selector provider telescope
        "hrsh7th/nvim-cmp", -- Optional: autocompletion for avante commands and mentions
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		-- {
		-- 	-- support for image pasting
		-- 	"HakonHarnes/img-clip.nvim",
		-- 	event = "VeryLazy",
		-- 	opts = {
		-- 		-- recommended settings
		-- 		default = {
		-- 			embed_image_as_base64 = false,
		-- 			prompt_for_file_name = false,
		-- 			drag_and_drop = {
		-- 				insert_mode = true,
		-- 			},
		-- 			-- required for Windows users
		-- 			use_absolute_path = true,
		-- 		},
		-- 	},
		-- },
		{
			-- Make sure to set this up properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
}
