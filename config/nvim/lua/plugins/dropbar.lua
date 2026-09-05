return {
	"Bekaboo/dropbar.nvim",
	event = "VeryLazy",
	init = function()
		-- Eagerly load the module so `_G.dropbar` exists as a global
		-- before any window redraw references `v:lua.dropbar()` via a
		-- winbar opt (set by other autocmds or restored sessions).
		-- The actual `setup()` (autocmds, winbar attach) still runs on
		-- `VeryLazy` below.
		pcall(require, "dropbar")
	end,
	config = function()
		require("dropbar").setup({})
		local dropbar_api = require("dropbar.api")
		vim.keymap.set("n", "<Leader>;", dropbar_api.pick, { desc = "Pick symbols in winbar" })
		vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
		vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
	end,
}