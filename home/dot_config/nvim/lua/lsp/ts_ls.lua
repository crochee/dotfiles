return {
	cmd = { "typescript-language-server", "--stdio" },
	filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" },
	root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
	single_file_support = true,
}
