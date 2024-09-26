local M = { "ellisonleao/glow.nvim", config = true, cmd = "Glow" }

function M.config()
	require("glow").setup({
		style = "dark",
		pager = false,
		width = 120,
	})
end

return M
