return {
	"kevinhwang91/nvim-bqf",
	enabled = not vim.g.vscode,
	ft = "qf",
	config = function()
		require("bqf").setup()
	end,
}
