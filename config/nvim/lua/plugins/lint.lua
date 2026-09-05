return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local lint = require("lint")
		for _, linter in ipairs({ "shellcheck", "jq", "yamllint", "codespell", "stylelint", "sqlfluff" }) do
			pcall(require, "lint.linters." .. linter)
		end
		lint.linters_by_ft = {
			sh = { "shellcheck" },
			bash = { "shellcheck" },
			json = { "jq" },
			yaml = { "yamllint" },
			markdown = { "codespell" },
			css = { "stylelint" },
			scss = { "stylelint" },
			less = { "stylelint" },
			sql = { "sqlfluff" },
		}
		vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
			callback = function()
				-- Only lint files under $HOME that have known content; skip huge or gitignored dirs.
				lint.try_lint()
			end,
		})
		vim.api.nvim_create_user_command("Lint", function()
			lint.try_lint()
		end, { desc = "Trigger nvim-lint on current buffer" })
	end,
}
