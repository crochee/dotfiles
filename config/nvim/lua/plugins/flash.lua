return {
	"folke/flash.nvim",
	event = "VeryLazy",
	config = function()
		require("flash").setup({
			modes = {
				char = {
					enabled = false,
				},
			},
		})
	end,
}
