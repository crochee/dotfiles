-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#pyright
-- 先下载anguage server
return {
	single_file_support = true,
	settings = {
		python = {
			analysis = {
				autoSearchPaths = true,
				diagnosticMode = "workspace",
				useLibraryCodeForTypes = true,
			},
		},
	},
	capabilities = require("lsp.utils").capabilities,
	on_attach = require("lsp.utils").on_attach,
}
