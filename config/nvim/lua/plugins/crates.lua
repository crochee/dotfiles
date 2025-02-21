local M = {
	"Saecki/crates.nvim",
	event = { "BufRead Cargo.toml" },
}

function M.config()
	require("crates").setup()
end

return M
