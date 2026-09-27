return {
	"nvim-lualine/lualine.nvim",
	-- 底部状态栏
	event = "VeryLazy",
	opts = {
		options = {
			disabled_filetypes = { "NvimTree" },
			component_separators = "",
			section_separators = "",
		},
		sections = {
			lualine_c = {
				{
					"filename",
					file_status = true, -- displays file status (readonly status, modified status)
					path = 2, -- 0 = just filename, 1 = relative path, 2 = absolute path
				},
			},
			lualine_x = {
				"lsp_status", -- 活跃 LSP 服务器名 + 进度旋转图标
				function()
					local sw = vim.api.nvim_get_option_value("shiftwidth", { buf = 0 })
					if type(sw) ~= "number" then
						return ""
					end
					return tostring(sw)
				end,
				"encoding",
				{
					"filetype",
					icons_enabled = true,
				},
			},
		},
	},
}