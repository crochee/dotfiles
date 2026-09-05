return {
	cmd = { "kotlin-language-server" },
	filetypes = { "kotlin" },
	root_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", ".git" },
	init_options = {
		storagePath = table.concat({ vim.env.XDG_DATA_HOME or vim.fn.expand("~/.local/share"), "kotlin_language_server" }, "/"),
	},
}
