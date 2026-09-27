return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local lint = require("lint")
		lint.linters_by_ft = {
			sh = { "shellcheck" },
			bash = { "shellcheck" },
			yaml = { "yamllint" },
			markdown = { "codespell" },
			css = { "stylelint" },
			scss = { "stylelint" },
			less = { "stylelint" },
			sql = { "sqlfluff" },
		}
		vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
			callback = function()
				lint.try_lint()
			end,
		})
		vim.api.nvim_create_user_command("Lint", function()
			lint.try_lint()
		end, { desc = "Trigger nvim-lint on current buffer" })
	end,
}
