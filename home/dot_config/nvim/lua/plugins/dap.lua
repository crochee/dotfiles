return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"theHamsta/nvim-dap-virtual-text",
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
		},
		keys = {
			{ "<leader>dc", function() require("dap").continue() end, desc = "DAP continue" },
			{ "<leader>dC", function() require("dap").run_to_cursor() end, desc = "DAP run to cursor" },
			{
				"<leader>de",
				function()
					require("dap").close()
					require("dap").terminate()
					require("dap.repl").close()
					require("dapui").close()
					require("dap").clear_breakpoints()
				end,
				desc = "DAP terminate all",
			},
			{ "<leader>dt", function() require("dap").toggle_breakpoint() end, desc = "DAP toggle breakpoint" },
			{ "<leader>dn", function() require("dap").step_over() end, desc = "DAP step over" },
			{ "<leader>do", function() require("dap").step_out() end, desc = "DAP step out" },
			{ "<leader>di", function() require("dap").step_into() end, desc = "DAP step into" },
			{ "<leader>dl", function() require("dap").run_last() end, desc = "DAP run last" },
			{
				"<leader>dh",
				function()
					local exp = vim.fn.input("expression: ")
					if exp ~= "" then
						require("dapui").eval(exp, {})
					end
				end,
				desc = "DAP evaluate expression",
			},
			{ "<leader>df", function() require("dapui").float_element() end, desc = "DAP float element" },
		},
		config = function()
			local dap = require("dap")

			-- adapters / configurations: lua/dap/{adapters,configurations}/
			dap.adapters.codelldb = require("dap.adapters.codelldb")
			dap.adapters.delve = require("dap.adapters.delve")
			local llvm = require("dap.configurations.llvm")
			dap.configurations.c = llvm.c
			dap.configurations.cpp = llvm.cpp
			dap.configurations.rust = llvm.rust
			dap.configurations.go = require("dap.configurations.go")

			-- 虚拟文本 + 断点图标
			require("nvim-dap-virtual-text").setup({ commented = true })
			vim.fn.sign_define("DapBreakpoint", { text = ">", texthl = "DiagnosticError" })
			vim.fn.sign_define("DapBreakpointCondition", { text = "?", texthl = "DiagnosticError" })
			vim.fn.sign_define("DapLogPoint", { text = ">", texthl = "DiagnosticInfo" })
			vim.fn.sign_define("DapStopped", { text = ">", texthl = "Constant", linehl = "debugPC" })
			vim.fn.sign_define("DapBreakpointRejected", { text = "X" })

			-- dapui：调试会话开始/结束自动开关
			local dapui = require("dapui")
			dapui.setup({
				icons = { expanded = "v", collapsed = ">", current_frame = ">" },
				mappings = {
					expand = { "<CR>", "<2-LeftMouse>" },
					open = "o",
					remove = "d",
					edit = "e",
					repl = "r",
					toggle = "t",
				},
				layouts = {
					{
						elements = { "scopes", "breakpoints", "stacks", "watches" },
						size = 40,
						position = "left",
					},
					{
						elements = { "repl", "console" },
						size = 10,
						position = "bottom",
					},
				},
				controls = {
					enabled = true,
					element = "repl",
					icons = {
						pause = "||",
						play = ">",
						step_into = "->",
						step_over = ">>",
						step_out = "<-",
						step_back = "<<",
						run_last = "R",
						terminate = "X",
					},
				},
				floating = {
					border = "single",
					mappings = { close = { "q", "<Esc>" } },
				},
				windows = { indent = 1 },
			})
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end
		end,
	},
	{
		"leoluz/nvim-dap-go",
		ft = "go",
		dependencies = { "mfussenegger/nvim-dap" },
		keys = {
			{ "<leader>dgt", function() require("dap-go").debug_test() end, desc = "Debug go test" },
			{ "<leader>dgl", function() require("dap-go").debug_last_test() end, desc = "Debug last go test" },
		},
		config = function()
			require("dap-go").setup()
		end,
	},
}
