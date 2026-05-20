return {
	"Saecki/crates.nvim",
	event = { "BufRead Cargo.toml" },
	config = function()
		require("crates").setup()
	end,
}
