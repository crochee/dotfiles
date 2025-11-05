return {
	"folke/trouble.nvim",
	enabled = not vim.g.vscode,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		require("trouble").setup({})
	end,
}
