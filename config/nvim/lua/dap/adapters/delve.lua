-- delve 适配器（dlv dap 模式）
return {
	type = "server",
	host = "127.0.0.1",
	port = "${port}",
	executable = {
		command = "dlv",
		args = { "dap", "-l", "127.0.0.1:${port}" },
	},
}
