return {
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		cmd = "Trouble",
		keys = {
			{
				"<leader>xx",
				function()
					require("trouble").toggle({ mode = "diagnostics" })
				end,
				desc = "Diagnostics (Trouble)",
			},
			{
				"<leader>xX",
				function()
					require("trouble").toggle({ mode = "diagnostics", filter = { buf = 0 } })
				end,
				desc = "Buffer Diagnostics (Trouble)",
			},
			{
				"<leader>xl",
				function()
					require("trouble").toggle({ mode = "loclist" })
				end,
				desc = "Location List (Trouble)",
			},
			{
				"<leader>xq",
				function()
					require("trouble").toggle({ mode = "quickfix" })
				end,
				desc = "Quickfix List (Trouble)",
			},
			{
				"<leader>xt",
				function()
					require("trouble").toggle({ mode = "todo_project", title = "Todo Comments" })
				end,
				desc = "Todo Comments (project root)",
			},
		},
		-- v3 默认 open_no_results=false：按下瞬间列表为空（LSP 还在分析）就只弹
		-- "No results" 且不开窗口——视图没建立，迟到的诊断永远进不来，表现成
		-- "时好时坏"。开着空窗口，DiagnosticChanged 事件会自动填充。
		opts = {
			auto_open = false,
			auto_close = false,
			auto_preview = false,
			open_no_results = true,
		},
		config = function(_, opts)
			local trouble = require("trouble")
			trouble.setup(opts)

			-- 内置 todo 模式固定从 nvim cwd 起扫（Search.search cwd="."）：在非项目
			-- 目录（$HOME、/tmp）会全量扫描、结果混入无关文件，还会撞上不可读目录
			-- 报 rg exit 2。注册一个以当前 buffer 项目根为范围的 todo 源。
			require("trouble.sources").register("todo_project", {
				config = {
					formatters = {
						todo_icon = function(ctx)
							local Config = require("todo-comments.config")
							return {
								text = Config.options.keywords[ctx.item.tag].icon,
								hl = "TodoFg" .. ctx.item.tag,
							}
						end,
					},
					modes = {
						todo_project = {
							desc = "todo comments (project root)",
							events = { "BufEnter", "BufWritePost" },
							source = "todo_project",
							groups = {
								{ "tag", format = "{todo_icon} {tag}" },
								{ "filename", format = "{file_icon} {filename} {count}" },
							},
							sort = { { buf = 0 }, "filename", "pos", "message" },
							format = "{todo_icon} {text} {pos}",
						},
					},
				},
				get = function(cb, ctx)
					local Search = require("todo-comments.search")
					local Item = require("trouble.item")
					-- 与 project.nvim 相同的根标记
					local markers = { ".git", "pom.xml", "*.csproj", "Makefile", "Cargo.toml", "go.mod", "package.json", "pyproject.toml" }
					local root = (ctx and ctx.main and vim.fs.root(ctx.main.buf, markers)) or vim.uv.cwd()
					Search.search(function(results)
						local items = {} ---@type trouble.Item[]
						for _, it in pairs(results) do
							items[#items + 1] = Item.new({
								buf = vim.fn.bufadd(it.filename),
								pos = { it.lnum, it.col - 1 },
								end_pos = { it.lnum, it.col - 1 + #it.tag },
								text = it.text,
								filename = it.filename,
								item = it,
								source = "todo_project",
							})
						end
						cb(items)
					end, { cwd = root })
				end,
			})
		end,
	},
	-- Profile.nvim: async-aware profiler（Chrome trace JSON，speedscope 可打开）
	{
		"stevearc/profile.nvim",
		lazy = true,
		-- 插件本身没有 :Profile 命令也没有 setup()，自己定义命令并按需加载
		init = function()
			vim.api.nvim_create_user_command("Profile", function(e)
				local profile = require("profile")
				local sub = e.fargs[1] or (profile.is_recording() and "stop" or "start")
				if sub == "start" then
					profile.start()
					vim.notify("profile: recording started")
				elseif sub == "stop" then
					local out = e.fargs[2] or "/tmp/nvim-profile.json"
					profile.stop(out)
					vim.notify("profile: wrote " .. out)
				elseif sub == "status" then
					vim.notify("recording=" .. tostring(profile.is_recording()))
				end
			end, { nargs = "*", desc = "Profile start/stop/status" })
		end,
	},
{
	"echasnovski/mini.animate",
	event = "VeryLazy",
	opts = function()
		local animate = require("mini.animate")
		return {
			resize = {
				timing = animate.gen_timing.linear({ duration = 200, target_fps = 60 }),
			},
			-- scroll animation disabled: j/k/Ctrl-d/Ctrl-u feel sluggish otherwise
			scroll = { enable = false },
		}
	end,
},
}