-- leader 键
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

local function dopts(desc)
	return { desc = desc, silent = true }
end

-- 保存（插入模式退出到 normal 并保存）
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", dopts("save"))

-- 清除搜索高亮
map("n", "<leader><space>", ":noh<CR>", dopts("clean highlight"))

-- visual 模式下缩进保持选区
map("v", "<", "<gv", dopts("indent left"))
map("v", ">", ">gv", dopts("indent right"))
-- 上下移动当前行 / 选区 → mini.move (plugins/mini.lua), 保持 register/marks

-- LSP inlay hint 开关
map("n", "<leader>ie", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, dopts("toggle inlay hints"))

