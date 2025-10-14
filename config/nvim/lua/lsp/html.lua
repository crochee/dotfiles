--Enable (broadcasting) snippet capability for completion

local opts = {
	capabilities = require("lsp.utils").capabilities,
	on_attach = require("lsp.utils").on_attach,
	single_file_support = true,
}

return opts
