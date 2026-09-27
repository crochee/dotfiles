return {
	-- mini.animate: 200ms window/resize animation. Require must be in config() phase.
	{
		"echasnovski/mini.animate",
		event = "VeryLazy",
		config = function()
			require("mini.animate").setup({
				resize = {
					timing = require("mini.animate").gen_timing.linear({
						duration = 200,
						target_fps = 60,
					}),
				},
				-- scroll animation off: default 250ms lag makes j/k/Ctrl-d/u feel sticky.
				scroll = { enable = false },
			})
		end,
	},
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
		-- v3 open_no_results default false: empty list at open hides DiagnosticChanged arrivals.
		-- Keep the empty window so late diagnostics fill in.
		opts = {
			auto_open = false,
			auto_close = false,
			auto_preview = false,
			open_no_results = true,
		},
		config = function(_, opts)
			local trouble = require("trouble")
			trouble.setup(opts)

			-- Built-in todo scans from nvim cwd: in $HOME or /tmp it scans everything and
			-- may hit unreadable dirs (rg exit 2). Register a project-root-scoped source.
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
					local markers = require("configs.root_markers")
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
	-- Profile.nvim: async-aware profiler (Chrome trace JSON; speedscope-compatible).
	-- Plugin ships no :Profile command; we define one and lazy-load the module.
	{
		"stevearc/profile.nvim",
		lazy = true,
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
}