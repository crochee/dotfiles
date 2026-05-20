return {
	-- Treesitter is a new parser generator tool that we can
	-- use in Neovim to power faster and more accurate
	-- syntax highlighting.
	{
		"nvim-treesitter/nvim-treesitter",
		build = function()
			require("nvim-treesitter.install").update({ with_sync = true })()
		end,
	},
	-- Show context of the current function
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = { "VeryLazy" },
		opts = { mode = "cursor", max_lines = 3 },
	},
}
