-- c / cpp / rust: codelldb launch
local config = {
	{
		name = "Launch file",
		type = "codelldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
	},
}

return {
	c = config,
	cpp = config,
	rust = {
		{
			name = "Launch binary",
			type = "codelldb",
			request = "launch",
			program = function()
				return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/target/debug/", "file")
			end,
			cwd = "${workspaceFolder}",
			sourceMap = {},
			sourceLanguages = { "rust" },
		},
	},
}
