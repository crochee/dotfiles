return {
	{
		"mason-org/mason.nvim",
		cmd = "Mason",
		opts = {
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
			pip = { use_uv = true },
		},
	},
	{
		"WhoIsSethDaniel/mason-tool-installer.nvim",
		dependencies = { "mason-org/mason.nvim" },
		event = "VeryLazy",
		opts = {
			-- Mason package names (LSP servers + formatters/linters + DAP).
			ensure_installed = {
				-- LSP (lspconfig name → mason name)
				"gopls", -- gopls
				"lua-language-server", -- lua_ls
				"bash-language-server", -- bashls
				"json-lsp", -- jsonls
				"pyright", -- pyright
				"vim-language-server", -- vimls
				"css-lsp", -- cssls
				"html-lsp", -- html
				"eslint-lsp", -- eslint
				"typescript-language-server", -- ts_ls
				"taplo", -- taplo
				"yaml-language-server", -- yamlls
				"clangd", -- clangd
				"jdtls", -- jdtls
				"kotlin-language-server", -- kotlin_language_server
				"prettier",
				"stylua",
				"shfmt",
				"gofumpt",
				"goimports-reviser",
				"sqlfmt",
				"vacuum",
				"codespell",
				"yamllint",
				"stylelint",
				"sqlfluff",
				-- DAP
				"delve",
				"codelldb",
			},
		},
	},
}
