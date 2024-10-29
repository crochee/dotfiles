local M = {
	"akinsho/toggleterm.nvim",
}
function M.config()
	local status, toggleterm = pcall(require, "toggleterm")
	if not status then
		vim.notify("没有找到 toggleterm")
		return
	end

	toggleterm.setup({
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
			vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
		end,
		shell = vim.o.shell,
		float_opts = {
			border = "double", -- 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
			winblend = 3,
			highlights = {
				border = "Normal",
				background = "Normal",
			},
		},
		winbar = {
			enabled = true,
			name_formatter = function(term) --  term: Terminal
				return term.name
			end,
		},
	})

	-- local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })
	function _LAZYGIT_OPEN(opts)
		opts = vim.tbl_deep_extend("force", {}, opts or {})

		local cmd = { "lazygit" }
		vim.list_extend(cmd, opts.args or {})

		require("toggleterm.terminal").Terminal
			:new({
				id = 1000, --[[ 解决lazygit关闭通用窗口问题 ]]
				dir = "git_dir",
				float_opts = {
					border = "curved", -- 'single' | 'double' | 'shadow' | 'curved' | ... other options supported by win open
				},
				cmd = table.concat(cmd, " "),
			})
			:toggle()
	end

	function _GIT_LOG()
		local range = function()
			if vim.fn.mode() == "n" then
				local pos = vim.api.nvim_win_get_cursor(0)
				return {
					pos[1],
					pos[1],
				}
			end

			return {
				vim.fn.getpos("v")[2],
				vim.fn.getpos(".")[2],
			}
		end
		local proportional_size = function(width_ratio, height_ratio)
			local screen_w = vim.opt.columns:get()
			local screen_h = vim.opt.lines:get() - vim.opt.cmdheight:get()
			local window_w = screen_w * width_ratio
			local window_h = screen_h * height_ratio
			local window_w_int = math.floor(window_w)
			local window_h_int = math.floor(window_h)
			local center_x = (screen_w - window_w) / 2
			local center_y = ((vim.opt.lines:get() - window_h) / 2) - vim.opt.cmdheight:get()
			return {
				row = center_y,
				col = center_x,
				width = window_w_int,
				height = window_h_int,
			}
		end
		local separator = function(length)
			local result = ""
			for _ = 1, length, 1 do
				result = result .. "-"
			end
			return result
		end
		local win_size_opts = proportional_size(0.6, 0.8)

		local file_name = vim.api.nvim_buf_get_name(0)
		local line_range = range()

		local gitdir = vim.fn.system(string.format("git -C %s rev-parse --show-toplevel", vim.fn.expand("%:p:h")))
		if vim.fn.matchstr(gitdir, "^fatal:.*") ~= "" then
			gitdir = vim.fn.expand(vim.trim(gitdir))
		end
		gitdir = vim.split(gitdir, "\n")[1]
		-- 构建 git log 命令
		local git_command =
			string.format("cd %s && git log -L %s,%s:%s", gitdir, line_range[1], line_range[2], file_name)
		-- 执行 git 命令并捕获输出
		local output = vim.trim(vim.fn.system(git_command))
		-- 设置缓冲区内容
		local log = vim.split(output, "\n")
		local new_list = {}
		for i, value in ipairs(log) do
			if i ~= 1 and i ~= 2 then
				table.insert(new_list, value)
			end
		end
		local new_log = {}
		local first_commit = true
		for i = 1, table.maxn(new_list), 1 do
			if string.match(new_list[i], "^commit") then
				if first_commit then
					first_commit = false
				else
					table.insert(new_log, separator(win_size_opts.width))
				end
			end
			table.insert(new_log, log[i])
		end
		log = new_log
		-- 创建一个新的缓冲区
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_option_value("modifiable", true, {
			buf = buf,
		})
		vim.api.nvim_set_option_value("filetype", "git", {
			buf = buf,
		})
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, log)
		vim.api.nvim_set_option_value("modifiable", false, {
			buf = buf,
		})
		-- 创建一个浮动窗口来展示缓冲区内容
		-- 设置浮动窗口的缓冲区
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
		-- set keymap
		vim.keymap.set("n", "q", function()
			pcall(vim.api.nvim_buf_delete, buf, {
				force = true,
			})
		end, {
			buffer = buf,
		})
	end
end

return M
