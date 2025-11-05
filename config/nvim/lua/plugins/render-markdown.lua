return {
	"MeanderingProgrammer/render-markdown.nvim",
	enabled = not vim.g.vscode,
	dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
	opts = {
		latex = { enabled = false }, -- default settings
	},
}
