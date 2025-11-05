return {
	"mason-org/mason.nvim",
	enabled = not vim.g.vscode,
	dependencies = {
		"nvim-lua/plenary.nvim",
		"b0o/schemastore.nvim",
		------ lsp
		"neovim/nvim-lspconfig",
		"zk-org/zk-nvim",
		-------- dap
		"jayp0521/mason-nvim-dap.nvim",
		{
			"mfussenegger/nvim-dap",
			dependencies = {
				{
					"rcarriga/nvim-dap-ui",
					dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
				},
				"theHamsta/nvim-dap-virtual-text",
			},
		},
		"nvim-telescope/telescope-dap.nvim",
		"leoluz/nvim-dap-go",
		----------linter
		{
			"jay-babu/mason-null-ls.nvim",
			event = { "BufReadPre", "BufNewFile" },
			dependencies = {
				"mason-org/mason.nvim",
				"nvimtools/none-ls.nvim",
			},
			config = function() end,
		},
		----formatter----
		"zapling/mason-conform.nvim",
	},
	config = function()
		require("mason").setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
			pip = { use_uv = true },
			-- ~/.local/share/nvim/mason
			install_root_dir = vim.fn.stdpath("data") .. "/mason",
		})

		-----------------dap Install List ---------------------
		require("daps.dapui")

		local dap_list = {
			{
				name = "delve",
				alone = true,
			},
			{
				name = "codelldb",
				alone = true,
			},
		}

		local dap_handlers = {}
		local dap_ensure_installed = {}

		for _, ele in pairs(dap_list) do
			table.insert(dap_ensure_installed, ele.name)

			if ele.alone then
				require("daps." .. ele.name)
			else
				dap_handlers[ele.name] = require("daps." .. ele.name)
			end
		end

		-- list the debug dependence that must be installed
		require("mason-nvim-dap").setup({
			ensure_installed = dap_ensure_installed,
			automatic_installation = true,
			handlers = dap_handlers,
		})

		-------------------- LSP Install List
		-- https://github.com/williamboman/nvim-lsp-installer#available-lsps
		-- { key: lsp_name, value: lsp_config }
		local lsp_servers = {
			gopls = require("lsp.gopls"),
			lua_ls = require("lsp.lua"),
			bashls = require("lsp.bashls"),
			jsonls = require("lsp.jsonls"),
			pyright = require("lsp.pyright"),
			vimls = require("lsp.vimls"),
			cssls = require("lsp.cssls"),
			html = require("lsp.html"),
			eslint = require("lsp.eslint"),
			ts_ls = require("lsp.tsserver"),
			taplo = require("lsp.taplo"),
			yamlls = require("lsp.yamlls"),
			zk = require("lsp.zk"),
			clangd = require("lsp.clangd"),
			jdtls = require("lsp.jdtls"),
			kotlin_language_server = require("lsp.kotlin_language_server"),
			typos_lsp = require("lsp.typos_lsp"),
		}

		local lsp_ensure_installed = { type = "list" }
		for name, config in pairs(lsp_servers) do
			table.insert(lsp_ensure_installed, name)
			if config.setup then
				local opts = vim.tbl_deep_extend("force", config, { setup = nil })
				config.setup(opts)
			else
				vim.lsp.config(name, config)
			end
		end
		vim.lsp.enable(lsp_ensure_installed)

		-------------------- Linter Install List

		require("null-ls").setup()
		require("mason-null-ls").setup({
			ensure_installed = { "shellcheck", "vacuum", "jq", "stylua", "stylelint", "codespell" },
			automatic_installation = true,
		})

		---------------- formatter----
		require("mason-conform").setup()
	end,
}
