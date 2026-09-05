return {
	"edolphin-ydf/goimpl.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		"nvim-treesitter/nvim-treesitter",
	},
	ft = "go",
	keys = {
		{ "<leader>im", function() require("telescope").extensions.goimpl.goimpl({}) end, desc = "Implement interface" },
	},
	config = function()
		require("telescope").load_extension("goimpl")
	end,
}
