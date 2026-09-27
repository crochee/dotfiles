-- crates.nvim: defaults fire HTTP to crates.io on every BufReadPost of Cargo.toml and on
-- every edit. Disable both — plugins shouldn't autoload network I/O without an explicit ask.
return {
	"Saecki/crates.nvim",
	event = { "BufRead Cargo.toml" },
	config = function()
		require("crates").setup({
			autoload = false,
			autoupdate = false,
		})
	end,
}