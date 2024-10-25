local opts = {
	cmd = { "gopls", "serve" },
	filetypes = { "go", "gomod", "gowork", "gotmpl" },
	root_dir = require("lspconfig/util").root_pattern("go.work", "go.mod", ".git"),
	single_file_support = true,
	settings = {
		gopls = {
			analyses = {
				unusedparams = true,
			},
			staticcheck = true,
		},
	},
	capabilities = require("lsp.utils").capabilities,
	on_attach = require("lsp.utils").on_attach,
}

return opts
