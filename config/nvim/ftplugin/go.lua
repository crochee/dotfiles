-- mason iferr config
-- Add iferr declaration
-- That's Lua of vimscript implementation of:
-- github.com/koron/iferr
function IFERR()
	local boff = vim.fn.wordcount().cursor_bytes
	local cmd = ("iferr -pos " .. boff)
	local data = vim.fn.systemlist(cmd, vim.fn.bufnr("%"))
	-- 增加一个空行
	data[#data + 1] = ""
	if vim.v.shell_error ~= 0 then
		vim.notify("command " .. cmd .. " exited with code " .. vim.v.shell_error)
		return
	end

	local pos = vim.fn.getcurpos()[2]
	vim.fn.append(pos, data)
	vim.cmd([[silent! normal! j=3j]])
	vim.fn.setpos(".", pos)
	vim.cmd([[silent! normal! 3j]])
end

local map = vim.keymap.set

map({ "i", "n" }, "<C-l>", "<CMD>lua IFERR()<CR>", { noremap = true, silent = true })
