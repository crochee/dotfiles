local M = {
	"kevinhwang91/nvim-bqf",
	ft = "qf",
}

function M.config()
	require("bqf").setup()
end

return M
