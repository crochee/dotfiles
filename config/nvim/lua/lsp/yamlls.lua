local opts = {
	single_file_support = true,
	on_attach = require("lsp.utils").on_attach,
	capabilities = require("lsp.utils").capabilities,
	settings = {
		redhat = {
			telemetry = {
				enabled = false,
			},
		},
		yaml = {
			format = {
				enable = true,
			},
			schemas = {
				["https://raw.githubusercontent.com/yannh/kubernetes-json-schema/refs/heads/master/v1.32.1-standalone-strict/all.json"] = "/*.k8s.yaml",
			},
		},
	},
}
return opts
