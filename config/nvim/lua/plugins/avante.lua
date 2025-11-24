return {
	"yetone/avante.nvim",
    enabled = not vim.g.vscode,
	event = "VeryLazy",
	-- enabled = false,
	version = false, -- Set this to "*" to always pull the latest release version, or set it to false to update to the latest code changes.
	opts = {
		provider = "streamlake",
		providers = {
			streamlake = {
				__inherited_from = "openai",
				api_key_name = "DEEPSEEK_API_KEY",
				-- api_key_name = "WQ_API_KEY",
				endpoint = "https://api.deepseek.com",
				-- endpoint = "https://wanqing.streamlakeapi.com/api/gateway/v1/endpoints",
				model = "deepseek-coder",
				-- model = "ep-bmn3kd-1761271125825670473",
			},
		},
		auto_suggestions_provider = "streamlake",
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
		acp_providers = {
			["codex"] = {
				command = "codex-acp",
				env = {
					NODE_NO_WARNINGS = "1",
					HOME = os.getenv("HOME"),
					PATH = os.getenv("PATH"),
					WQ_API_KEY = os.getenv("WQ_API_KEY"),
					DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY"),
				},
			},
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
