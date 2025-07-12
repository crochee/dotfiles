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
		"hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				-- recommended settings
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					-- required for Windows users
					use_absolute_path = true,
				},
			},
		},
		{
			-- Make sure to set this up properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
	windows = {
		input = {
			prefix = "> ",
			height = 10,
		},
	},
	custom_tools = {
		{
			name = "run_go_tests", -- Unique name for the tool
			description = "Run Go unit tests and return results", -- Description shown to AI
			command = "go test -v ./...", -- Shell command to execute
			param = { -- Input parameters (optional)
				type = "table",
				fields = {
					{
						name = "target",
						description = "Package or directory to test (e.g. './pkg/...' or './internal/pkg')",
						type = "string",
						optional = true,
					},
				},
			},
			returns = { -- Expected return values
				{
					name = "result",
					description = "Result of the fetch",
					type = "string",
				},
				{
					name = "error",
					description = "Error message if the fetch was not successful",
					type = "string",
					optional = true,
				},
			},
			func = function(params, on_log, on_complete) -- Custom function to execute
				local target = params.target or "./..."
				return vim.fn.system(string.format("go test -v %s", target))
			end,
		},
	},
}
