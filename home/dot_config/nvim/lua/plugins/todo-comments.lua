return {
	"folke/todo-comments.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	keys = {
		{ "<leader>st", "<cmd>TodoTelescope<cr>", desc = "TODO comments" },
	},
	config = function()
		require("todo-comments").setup({
			signs = false,
			keywords = { FIXME = { alt = { "FIX", "BUG" } } },
		})
		-- VeryLazy fires before telescope's todo-comments extension is on rtp; defer to LazyDone.
		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyDone",
			once = true,
			callback = function()
				pcall(require("telescope").load_extension, "todo_comments")
			end,
		})
	end,
}