-- iferr (github.com/koron/iferr CLI) — thin vim wrapper: invoke CLI, paste below cursor.
local function iferr()
	local boff = vim.fn.wordcount().cursor_bytes
	local cmd = "iferr -pos " .. boff
	-- systemlist {input} must be string/list; passing bufnr gives empty stdin and
	-- an empty error-handling block. Use full buffer lines (koron/iferr upstream idiom).
	local data = vim.fn.systemlist(cmd, vim.fn.getline(1, "$"))
	if vim.v.shell_error ~= 0 then
		vim.notify("iferr exited with code " .. vim.v.shell_error, vim.log.levels.ERROR)
		return
	end
	data[#data + 1] = ""

	local pos = vim.fn.getcurpos()[2]
	vim.fn.append(pos, data)
	vim.cmd([[silent! normal! j=3j]])
	vim.fn.setpos(".", { 0, pos + 1, 1, 0 })
	vim.cmd([[silent! normal! 3j]])
end

vim.keymap.set({ "i", "n" }, "<C-l>", iferr, { noremap = true, silent = true, buffer = true, desc = "iferr generate" })
