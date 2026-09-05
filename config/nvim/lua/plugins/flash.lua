return {
	"folke/flash.nvim",
	event = "VeryLazy",
	keys = {
		{ "<leader>s", function() require("flash").jump() end, mode = { "n", "x", "o" }, desc = "Flash" },
		{ "<leader>e", function() require("flash").treesitter() end, mode = { "n", "x", "o" }, desc = "Flash Treesitter" },
		{ "<leader>re", function() require("flash").remote() end, mode = { "n", "x", "o" }, desc = "Remote Flash" },
		{ "<leader>v", function() require("flash").treesitter_search() end, mode = { "n", "x", "o" }, desc = "Treesitter Search" },
	},
	opts = {},
}
