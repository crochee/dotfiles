-- leader 键
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local map = vim.keymap.set

local function dopts(desc)
	return { desc = desc, noremap = true, silent = true }
end

-- 保存（插入模式退出到 normal 并保存）
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", dopts("save"))

-- 清除搜索高亮
map("n", "<leader><space>", ":noh<CR>", dopts("clean highlight"))

-- visual 模式下缩进保持选区
map("v", "<", "<gv", dopts("indent left"))
map("v", ">", ">gv", dopts("indent right"))

-- 上下移动当前行 / 选区
map("n", "<A-j>", "<cmd>m .+1<cr>==", dopts("Move Down"))
map("n", "<A-k>", "<cmd>m .-2<cr>==", dopts("Move Up"))
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", dopts("Move Down"))
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", dopts("Move Up"))
map("v", "<A-j>", ":m '>+1<cr>gv=gv", dopts("move down with selection"))
map("v", "<A-k>", ":m '<-2<cr>gv=gv", dopts("move up with selection"))

-- LSP inlay hint 开关
map("n", "<leader>ie", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, dopts("toggle inlay hints"))

