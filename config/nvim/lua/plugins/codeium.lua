local M = {
    -- "aliaksandr-trush/codeium.nvim",
	"Exafunction/codeium.nvim",
    commit = "f74f999",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"hrsh7th/nvim-cmp",
	},
	event = "BufEnter",
}

function M.config()
	require("codeium").setup({})
end

return M
