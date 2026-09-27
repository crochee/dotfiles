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
				"yaml-language-server", -- yamls
				"clangd", -- clangd
				"jdtls", -- jdtls
				"kotlin-language-server", -- kotlin_language_server
				-- formatters / linters (对应 conform.nvim + nvim-lint 引用)
				"stylua",
				"shfmt",
				"gofumpt",
				"goimports-reviser",
				"sqlfmt",
				"ruff", -- python: ruff_format + ruff_organize_imports
				"clang-format", -- c/cpp
				"prettier", -- markdown
				"biome", -- js/ts/json/yaml/css/html
				"shellcheck",
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
