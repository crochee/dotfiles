local opts = {
	init_options = {
		-- Enables caching and use project root to store cache data.
		storagePath = table.concat({ vim.env.XDG_DATA_HOME, "kotlin_language_server" }, "/"),
	},
	capabilities = require("lsp.utils").capabilities,
	on_attach = require("lsp.utils").on_attach,
}

return opts
