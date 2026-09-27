return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"nvim-neotest/neotest-go",
		"rouge8/neotest-rust",
		"nvim-neotest/neotest-python",
		"nvim-neotest/neotest-jest",
	},
	cmd = "Neotest",
	keys = {
		{ "<leader>tt", function() require("neotest").run.run() end, desc = "Run nearest test" },
		{ "<leader>tT", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run tests in file" },
		{ "<leader>tr", function() require("neotest").run.run_last() end, desc = "Run last test" },
		{ "<leader>tl", function() require("neotest").run.run_last({ failed = true }) end, desc = "Re-run failed" },
		{ "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
		{ "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Test output" },
		{ "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Test output panel" },
		{ "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-go")({
					args = { "-count=1" },
					experimental = {
						test_table = true,
					},
				}),
				require("neotest-rust"),
				require("neotest-python")({
					python = "python3",
				}),
				require("neotest-jest"),
			},
			status = {
				enabled = true,
			},
			output = {
				enabled = true,
				open_message = "Open",
			},
		})
	end,
}
