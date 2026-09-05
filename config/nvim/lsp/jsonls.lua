return {
	cmd = { "vscode-json-language-server", "--stdio" },
	filetypes = { "json", "jsonc" },
	root_markers = { ".git", "package.json" },
	single_file_support = true,
	init_options = {
		provideFormatter = true,
	},
}
