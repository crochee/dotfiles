return {
	"sainnhe/everforest",
	lazy = false,
	priority = 1000,
	config = function()
		vim.o.background = "dark"
		vim.g.everforest_background = "hard"
		vim.g.everforest_better_performace = 1
		vim.cmd.colorscheme("everforest")
	end,
}
