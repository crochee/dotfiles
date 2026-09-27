-- toggleterm: terminal container + hand-rolled lazygit / git-log floats.
-- lazygit + git log surface is too small to justify vim-fugitive / lazygit.nvim.
--
--   <C-\>          open/close default terminal
--   <leader>th/tv/ta/tf   toggle horizontal/vertical/tab/float terminal
--   <leader>tg     lazygit float
--   <leader>tF     lazygit current file (-f <file>)
--   <leader>gl     git log -L (normal: line / visual: range)
--   <leader>lt     send line/selection to terminal

return {
	"akinsho/toggleterm.nvim",
	keys = {
		"<C-\\>",
		{ "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal horizontal" },
		{ "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", desc = "Terminal vertical" },
		{ "<leader>ta", "<cmd>ToggleTerm direction=tab<cr>", desc = "Terminal tab" },
		{ "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal float" },
		{ "<leader>tg", function() _LAZYGIT_OPEN() end, desc = "Lazygit" },
		{
			"<leader>tF",
			function()
				local file = vim.api.nvim_buf_get_name(0)
				if file == "" or vim.fn.isdirectory(file) == 1 then
					vim.notify("tF: not a file buffer", vim.log.levels.WARN)
					return
				end
				_LAZYGIT_OPEN({ args = { "-f", file } })
			end,
			desc = "Lazygit current file history",
		},
		{ "<leader>gl", function() _GIT_LOG() end, mode = { "n", "v", "x" }, desc = "Git log for line" },
		{
			"<leader>lt",
			function()
				if vim.fn.mode() == "n" then
					require("toggleterm").send_lines_to_terminal("single_line", true, { args = vim.v.count })
					return
				end
				require("toggleterm").send_lines_to_terminal("visual_selection", true, { args = vim.v.count })
			end,
			mode = { "n", "v", "x" },
			desc = "Send line to terminal",
		},
	},
	config = function()
		require("toggleterm").setup({
			open_mapping = [[<C-\>]],
			hide_numbers = true,
			shade_filetypes = {},
			shade_terminals = true,
			shading_factor = 2,
			start_in_insert = true,
			insert_mappings = true,
			persist_size = true,
			direction = "float",
			close_on_exit = true,
			on_open = function(term)
				vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = term.bufnr, silent = true })
			end,
			shell = vim.o.shell,
			float_opts = {
				border = "double",
				winblend = 3,
				highlights = {
					border = "Normal",
					background = "Normal",
				},
			},
			winbar = { enabled = true },
		})

		-- Resolve git toplevel in `dir`; return nil on failure. argv-array form avoids
		-- shell injection.
		local function git_toplevel(dir)
			local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
			if vim.v.shell_error ~= 0 then
				return nil
			end
			local top = out[1]
			if not top or top == "" then
				return nil
			end
			return top
		end

		-- LazyGit float (fixed id=1000 reuses one Terminal across opens).
		-- Terminal.cmd takes only a string; shellescape each arg separately so paths
		-- with spaces/metachars stay safe.
		function _LAZYGIT_OPEN(opts)
			opts = vim.tbl_deep_extend("force", {}, opts or {})

			local argv = { "lazygit" }
			vim.list_extend(argv, opts.args or {})
			local cmd = table.concat(vim.tbl_map(vim.fn.shellescape, argv), " ")

			require("toggleterm.terminal").Terminal
				:new({
					id = 1000,
					dir = git_toplevel(vim.fn.expand("%:p:h")) or vim.fn.getcwd(),
					float_opts = { border = "curved" },
					cmd = cmd,
				})
				:toggle()
		end

		-- Centered float sized as a fraction of the screen.
		local proportional_size = function(width_ratio, height_ratio)
			local screen_w = vim.opt.columns:get()
			local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
			local window_w = screen_w * width_ratio
			local window_h = screen_h * height_ratio
			local center_x = (screen_w - window_w) / 2
			local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
			return {
				row = center_y,
				col = center_x,
				width = math.floor(window_w),
				height = math.floor(window_h),
			}
		end

		-- git log -L over a line range; strip git's two header lines, add a separator
		-- between commits.
		function _GIT_LOG()
			-- 1-indexed inclusive range: visual selection, else current line.
			local range = function()
				if vim.fn.mode() == "n" then
					local pos = vim.api.nvim_win_get_cursor(0)
					return pos[1], pos[1]
				end
				local start = vim.fn.getpos("v")[2]
				local stop = vim.fn.getpos(".")[2]
				if start > stop then
					start, stop = stop, start
				end
				return start, stop
			end

			local file_name = vim.api.nvim_buf_get_name(0)
			if file_name == "" then
				vim.notify("git log: unnamed buffer", vim.log.levels.WARN)
				return
			end

			-- Resolve git root: prefer buffer dir, fall back to cwd.
			local cwd = vim.fn.fnamemodify(file_name, ":p:h")
			if cwd == "" then
				cwd = vim.fn.getcwd()
			end
			local gitdir = git_toplevel(cwd) or git_toplevel(vim.fn.getcwd())
			if not gitdir then
				vim.notify("git log: not in a git repo", vim.log.levels.WARN)
				return
			end

			-- argv-array form: paths and line numbers never enter a shell.
			local start_line, stop_line = range()
			local output = vim.fn.systemlist({
				"git",
				"-C",
				gitdir,
				"log",
				"-L",
				string.format("%d,%d:%s", start_line, stop_line, file_name),
			})
			if vim.v.shell_error ~= 0 then
				vim.notify("git log failed: " .. (output[1] or "unknown"), vim.log.levels.WARN)
				return
			end

			-- Strip git's first two header lines ("commit ..." and "diff --git ...").
			local new_list = {}
			for i = 3, #output do
				table.insert(new_list, output[i])
			end

			-- commit 之间加分隔线
			local win_size_opts = proportional_size(0.6, 0.8)
			local sep = string.rep("-", win_size_opts.width)
			local new_log = {}
			local first_commit = true
			for _, line in ipairs(new_list) do
				if line:match("^commit ") then
					if first_commit then
						first_commit = false
					else
						table.insert(new_log, sep)
					end
				end
				table.insert(new_log, line)
			end

			local buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_set_option_value("modifiable", true, { buf = buf })
			vim.api.nvim_set_option_value("filetype", "git", { buf = buf })
			vim.api.nvim_buf_set_lines(buf, 0, -1, false, new_log)
			vim.api.nvim_set_option_value("modifiable", false, { buf = buf })
			vim.api.nvim_win_set_buf(
				vim.api.nvim_open_win(buf, true, {
					relative = "editor",
					width = win_size_opts.width,
					height = win_size_opts.height,
					row = win_size_opts.row,
					col = win_size_opts.col,
					style = "minimal",
					border = "rounded",
					title = "git history for select",
					title_pos = "center",
				}),
				buf
			)
			vim.keymap.set("n", "q", function()
				pcall(vim.api.nvim_buf_delete, buf, { force = true })
			end, { buffer = buf })
		end
	end,
}
