-- package.path 在所有平台都用 ';' 分隔（Lua 固定语义，Windows 亦然），
-- 直接按 ';' split 即可；按首字符猜分隔符会得到 '.'，切出一堆垃圾。
local runtime_path = vim.split(package.path, ";")
-- 同时把 nvim 的 runtime 路径也告诉 server（兼容 vscode-style "lua/?.lua"）
table.insert(runtime_path, "lua/?.lua")
table.insert(runtime_path, "lua/?/init.lua")

return {
	cmd = { "lua-language-server" },
	filetypes = { "lua" },
	root_markers = { ".luarc.json", ".luarc.jsonc", ".luacheckrc", ".stylua.toml", "stylua.toml", ".git" },
	single_file_support = true,
	settings = {
		Lua = {
			runtime = {
				version = "LuaJIT",
				path = runtime_path,
			},
			diagnostics = {
				globals = { "vim" },
			},
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			telemetry = {
				enable = false,
			},
			format = {
				enable = true,
				defaultConfig = {
					indent_style = "space",
					indent_size = "2",
				},
			},
		},
	},
}
