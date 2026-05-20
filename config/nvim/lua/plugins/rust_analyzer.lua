-- https://github.com/neovim/nvim-lspconfig/blob/master/doc/server_configurations.md#rust_analyzer

return {
	"mrcjkb/rustaceanvim",
	version = "^6", -- Recommended
	ft = { "rust" },
	dependencies = { "mason-org/mason.nvim", "neovim/nvim-lspconfig" },
	-- enabled = false,
	init = function()
		vim.g.rustaceanvim = function()
			local extension_path = vim.fn.expand("$MASON/packages/codelldb/extension")
			local codelldb_path = extension_path .. "/adapter/codelldb"
			local liblldb_path = ""
			if vim.loop.os_uname().sysname:find("Windows") then
				liblldb_path = extension_path .. "lldb\\bin\\liblldb.dll"
			elseif vim.fn.has("mac") == 1 then
				liblldb_path = extension_path .. "lldb/lib/liblldb.dylib"
			else
				liblldb_path = extension_path .. "lldb/lib/liblldb.so"
			end
			return {
				server = {
					settings = function(project_root)
						local ra = require("rustaceanvim.config.server")
						return ra.load_rust_analyzer_settings(project_root, {
							settings_file_pattern = "rust-analyzer.json",
						})
					end,
					default_settings = {
						["rust-analyzer"] = {
							cargo = {
								allFeatures = true,
								loadOutDirsFromCheck = true,
								runBuildScripts = true,
								buildScripts = {
									enable = true,
								},
							},
							checkOnSave = true,
							procMacro = {
								enable = true,
							},
						},
					},
					capabilities = require("lsp.utils").capabilities,
					on_attach = require("lsp.utils").on_attach,
				},
				dap = {
					adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb_path, liblldb_path),
				},
				tools = {
					test_executor = "termopen",
					on_initialized = function()
						vim.cmd([[
	                augroup RustLSP
	                  autocmd CursorHold                      *.rs silent! lua vim.lsp.buf.document_highlight()
	                  autocmd CursorMoved,InsertEnter         *.rs silent! lua vim.lsp.buf.clear_references()
	                  autocmd BufEnter,CursorHold,InsertLeave *.rs silent! lua vim.lsp.codelens.refresh()
	                augroup END
	              ]])
					end,
				},
			}
		end
	end,
}
