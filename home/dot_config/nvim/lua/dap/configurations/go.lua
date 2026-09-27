-- go: delve launch（远程 attach 见 dap-go）
return {
	{
		type = "delve",
		name = "Debug",
		request = "launch",
		program = "${file}",
	},
	{
		type = "delve",
		name = "Debug test",
		request = "launch",
		mode = "test",
		program = "${file}",
	},
	{
		type = "delve",
		name = "Attach to process",
		request = "attach",
		process_id = require("dap.utils").pick_process,
	},
}
