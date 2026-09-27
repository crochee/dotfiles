return {
	cmd = { "yaml-language-server", "--stdio" },
	filetypes = { "yaml" },
	root_markers = { ".git" },
	single_file_support = true,
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
