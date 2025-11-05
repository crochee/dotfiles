return {
	"nvim-lua/lsp-status.nvim",
	enabled = not vim.g.vscode,
	config = function()
		local lsp_status = require("lsp-status")
		lsp_status.register_progress()
		lsp_status.config({
			status_symbol = " ",
		})
	end,
}
