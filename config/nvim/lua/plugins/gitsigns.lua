local M = {
	"lewis6991/gitsigns.nvim",
}

function M.config()
	require("gitsigns").setup({
		attach_to_untracked = true,
		on_attach = function(bufnr)
			local function map(mode, l, r, opts)
				opts = vim.tbl_extend("force", { noremap = true, silent = true }, opts or {})
				opts.buffer = bufnr
				vim.keymap.set(mode, l, r, opts)
			end
			require("configs.keymaps").gitsigns(map)
		end,
	})

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
		-- 构建 git log 命令
		local git_command = string.format("git log -L %s,%s:%s", line_range[1], line_range[2], file_name)
		-- 执行 git 命令并捕获输出
		local output = vim.trim(vim.fn.system(git_command))
		-- 创建一个新的缓冲区
		local buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_set_option_value("filetype", "git", {
			buf = buf,
		})
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
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, log)
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
