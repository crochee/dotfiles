-- setting leader key to " "
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 本地变量
local map = vim.keymap.set

local opts = {
	noremap = true, --禁止递归
	silent = true, --执行命令时不回显内容
}

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v", --v
--   visual_block_mode = "x", -- C_v
--   term_mode = "t",
--   command_mode = "c",

local function dopts(desc)
	return { desc = desc, noremap = true, silent = true }
end

-- save 插入模式下保存并退出到正常模式
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", dopts("save and exit"))

-- Clean search (highlight)取消高亮
map("n", "<leader><space>", ":noh<CR>", dopts("clean highlight"))

------------------------- visual模式下缩进代码-----------

map("v", "<", "<gv", dopts("indent left"))
map("v", ">", ">gv", dopts("indent right"))

-- 上下移动选中文本
-- Move Lines
map("n", "<A-j>", "<cmd>m .+1<cr>==", dopts("Move Down"))
map("n", "<A-k>", "<cmd>m .-2<cr>==", dopts("Move Up"))
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", dopts("Move Down"))
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", dopts("Move Up"))
map("v", "<A-j>", ":m '>+1<cr>gv=gv", dopts("move down with selection"))
map("v", "<A-k>", ":m '<-2<cr>gv=gv", dopts("move up with selection"))

-- 插件快捷键
local pluginKeys = {}

-------------------------- nvimTree 目录树插件 ---------------------
map("n", "<leader>ll", ":NvimTreeToggle<CR>", dopts("toggle nvimtree"))
-- 列表快捷键
pluginKeys.nvimTree = function(bufnr)
	local api = require("nvim-tree.api")

	local function opt(desc)
		return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
	end
	map("n", "<CR>", api.node.open.edit, opt("Open"))
	map("n", "<2-LeftMouse>", api.node.open.edit, opt("Open"))
	map("n", "<Tab>", api.node.open.preview, opt("Open Preview"))
	map("n", ".", api.tree.toggle_hidden_filter, opt("Toggle Dotfiles"))
	map("n", "i", api.tree.toggle_gitignore_filter, opt("Toggle Git Ignore"))
	map("n", "f", api.live_filter.start, opt("Filter"))
	map("n", "F", api.live_filter.clear, opt("Clean Filter"))
	map("n", "a", api.fs.create, opt("Create"))
	map("n", "d", api.fs.remove, opt("Delete"))
	map("n", "r", api.fs.rename, opt("Rename"))
	map("n", "x", api.fs.cut, opt("Cut"))
	map("n", "c", api.fs.copy.node, opt("Copy"))
	map("n", "p", api.fs.paste, opt("Paste"))
	map("n", "R", api.tree.reload, opt("Refresh"))
	map("n", "A", api.tree.expand_all, opt("Expand All"))
	map("n", "yn", api.fs.copy.filename, opt("Copy Name"))
	map("n", "yr", api.fs.copy.relative_path, opt("Copy Relative Path"))
	map("n", "ya", api.fs.copy.absolute_path, opt("Copy Absolute Path"))
end

----------------------------------- bufferline --------------
-- Buffer nav
map("n", "<leader>q", ":BufferLineCyclePrev<CR>", dopts("move previous buffer"))
map("n", "<leader>w", ":BufferLineCycleNext<CR>", dopts("move next buffer"))
-- Close buffer
map("n", "<leader>cc", ":bd<CR>", dopts("close current buffer"))
map("n", "<leader>cr", ":BufferLineCloseRight<CR>", dopts("close right buffers"))
map("n", "<leader>cl", ":BufferLineCloseLeft<CR>", dopts("close left buffers"))
map("n", "<leader>co", ":BufferLineCloseRight<CR>:BufferLineCloseLeft<CR>", dopts("close other buffers"))

------------------------------- Telescope  文件搜索 -------------------------
map("n", "<leader>ff", ":Telescope find_files<CR>", opts)
map("n", "<leader>fg", ":Telescope live_grep<CR>", opts)
map("n", "<leader>fs", ":Telescope lsp_document_symbols<CR>", opts)
map("n", "<leader>fb", ":Telescope buffers<CR>", opts)
map("n", "<leader>fh", ":Telescope help_tags<CR>", opts)
map("n", "<leader>fp", ":Telescope projects<CR>", opts)
map("n", "<leader>fc", ":Telescope command_history<CR>", opts)

-- Telescope 列表中 插入模式快捷键
pluginKeys.telescopeList = {
	i = {
		-- 上下移动
		["<C-j>"] = "move_selection_next",
		["<C-k>"] = "move_selection_previous",
		-- 历史记录
		["<Down>"] = "cycle_history_next",
		["<Up>"] = "cycle_history_prev",
		-- 关闭窗口
		["<C-c>"] = "close",
		-- 预览窗口上下滚动
		["<C-u>"] = "preview_scrolling_up",
		["<C-d>"] = "preview_scrolling_down",
	},
}

---------------------- lsp 编程语言设置相关（代码跳转提示等）-------------------
-- lsp 回调函数快捷键设置
pluginKeys.maplsp = function(mapbuf)
	-- rename
	mapbuf("n", "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
	-- code action
	mapbuf("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
	-- go xx
	mapbuf("n", "<leader>gd", "<cmd>lua vim.lsp.buf.definition()<CR>", opts)
	mapbuf("n", "<leader>gh", "<cmd>lua vim.lsp.buf.hover()<CR>", opts)
	mapbuf("n", "<leader>gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", opts)
	mapbuf("n", "<leader>gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
	mapbuf("n", "<leader>gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
	-- diagnostic
	mapbuf("n", "<leader>go", "<cmd>lua vim.diagnostic.open_float()<CR>", opts)
	mapbuf("n", "<leader>gp", "<cmd>lua vim.diagnostic.goto_prev()<CR>", opts)
	mapbuf("n", "<leader>gn", "<cmd>lua vim.diagnostic.goto_next()<CR>", opts)
	mapbuf("n", "<leader>gq", "<cmd>lua vim.diagnostic.setloclist()<CR>", opts)

	mapbuf("n", "<leader>gs", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
	-- mapbuf('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opt)
	-- mapbuf('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opt)
	-- mapbuf('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opt)
	mapbuf("n", "<space>gtd", "<cmd>lua vim.lsp.buf.type_definition()<CR>", opts)
end

map({ "n", "v", "x" }, "<leader>fm", function()
	require("conform").format({ async = true, lsp_fallback = true }, function(err)
		if not err then
			if vim.fn.mode() ~= "n" then
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
			end
		end
	end)
end, dopts("format code"))
map("n", "<leader>=", "<cmd>DiffFormat<CR>", opts)

map("n", "<leader>tc", ':lua require("treesitter-context").go_to_context()<CR>', opts)
-- switch lspinlayHit
map(
	"n",
	"<leader>ie",
	"<CMD>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), {bufnr=0})<CR>",
	opts
)

-------------------- nvim-cmp 自动补全 --------------------------
pluginKeys.cmp = function(cmp)
	return {
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				if #cmp.get_entries() == 1 then
					cmp.confirm({ select = true })
				else
					cmp.select_next_item()
				end
			else
				fallback() -- The fallback function sends a already mapped key. In this case, it's probably `<Tab>`.
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				if #cmp.get_entries() == 1 then
					cmp.confirm({ select = true })
				else
					cmp.select_prev_item()
				end
			else
				fallback()
			end
		end, { "i", "s" }),
		["<C-b>"] = cmp.mapping(cmp.mapping.scroll_docs(-4), { "i", "c" }),
		["<C-f>"] = cmp.mapping(cmp.mapping.scroll_docs(4), { "i", "c" }),
		["<C-Space>"] = cmp.mapping(cmp.mapping.complete(), { "i", "c" }),
		["<C-e>"] = cmp.mapping({
			i = cmp.mapping.abort(),
			c = cmp.mapping.close(),
		}),
		["<CR>"] = function(fallback)
			-- Don't block <CR> if signature help is active
			if
				not cmp.visible()
				or not cmp.get_selected_entry()
				or cmp.get_selected_entry().source.name == "nvim_lsp_signature_help"
			then
				fallback()
			else
				cmp.confirm({ select = false })
			end
		end,
	}
end

--------------------- floating terminal -----------------------------
-- toggleTerm & Lazygit
map("n", "<leader>tg", "<CMD>lua _LAZYGIT_OPEN()<CR>", dopts("toggle lazygit tirminal"))

map("n", "<leader>tF", function()
	local git_path = vim.api.nvim_buf_get_name(0)
	_LAZYGIT_OPEN({ args = { "-f", vim.trim(git_path) } })
end, dopts("Lazygit Current File History"))

-- toggleterm
map("n", "<leader>th", "<CMD>ToggleTerm direction=horizontal<CR>", opts)
map("n", "<leader>tv", "<CMD>ToggleTerm direction=vertical<CR>", opts)
map("n", "<leader>ta", "<CMD>ToggleTerm direction=tab<CR>", opts)
map("n", "<leader>tf", "<CMD>ToggleTerm direction=float<CR>", opts)

-- git history for select
map({ "n", "v", "x" }, "<leader>gl", "<Cmd>lua _GIT_LOG()<CR>", dopts("git log history for select"))

map({ "n", "v", "x" }, "<leader>lt", function()
	if vim.fn.mode() == "n" then
		require("toggleterm").send_lines_to_terminal("single_line", true, { args = vim.v.count })
		return
	end
	require("toggleterm").send_lines_to_terminal("visual_selection", true, { args = vim.v.count })
end, dopts("send to terminal"))

----------------------dap debug ------------------------------------
-- Begin
map("n", "<leader>dc", ":lua require('dap').continue()<CR>", opts)
map("n", "<leader>dC", ":lua require('dap').run_to_cursor()<CR>", opts)
-- Stop
map(
	"n",
	"<leader>de",
	":lua require'dap'.close()<CR>"
		.. ":lua require'dap'.terminate()<CR>"
		.. ":lua require'dap.repl'.close()<CR>"
		.. ":lua require'dapui'.close()<CR>"
		.. ":lua require('dap').clear_breakpoints()<CR>"
		.. "<C-w>o<CR>",
	opts
)
-- Set BreakPoint
map("n", "<leader>dt", ":lua require('dap').toggle_breakpoint()<CR>", opts)
--  stepOver, stepOut, stepInto
map("n", "<leader>dn", ":lua require'dap'.step_over()<CR>", opts)
map("n", "<leader>do", ":lua require'dap'.step_out()<CR>", opts)
map("n", "<leader>di", ":lua require'dap'.step_into()<CR>", opts)
map("n", "<leader>dl", ":lua require'dap'.run_last()<CR>", opts)
-- Pop-ups
map("n", "<leader>dh", function()
	local exp = vim.fn.input("expression: ")
	if exp == "" then
		require("dapui").eval()
	else
		require("dapui").eval(exp)
	end
end, opts)
-- map("n", "<leader>dh", ":lua require'dapui'.eval()<CR>", opts)
map("n", "<leader>df", ":lua require'dapui'.float_element()<CR>", opts)

-- golang debug test
map("n", "<leader>dgt", ":lua require('dap-go').debug_test()<CR>", opts)
map("n", "<leader>dgl", ":lua require('dap-go').debug_last_test()<CR>", opts)

------------------------gotests golang单元测试自动生成-----------------------
map("n", "<leader>ge", ":GoTests<CR>", opts)
map("n", "<leader>gta", ":GoTestsAll<CR>", opts)
map("n", "<leader>gte", ":GoTestsExported<CR>", opts)

----------------------git-conflict------------------------
map("n", "<leader>gco", "<Plug>(git-conflict-ours)")
map("n", "<leader>gct", "<Plug>(git-conflict-theirs)")
map("n", "<leader>gcb", "<Plug>(git-conflict-both)")
map("n", "<leader>gc0", "<Plug>(git-conflict-none)")
map("n", "<leader>gcp", "<Plug>(git-conflict-prev-conflict)")
map("n", "<leader>gcn", "<Plug>(git-conflict-next-conflict)")

-----------------------goimpl---------------------------------
map(
	"n",
	"<leader>im",
	"<Cmd>lua require'telescope'.extensions.goimpl.goimpl{}<CR>",
	dopts("go struct implement interface")
)

----------------------zk-------------------------------------
-- Create a new note after asking for its title.
map("n", "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", opts)

-- Open notes.
map("n", "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", opts)
-- Open notes associated with the selected tags.
map("n", "<leader>zt", "<Cmd>ZkTags<CR>", opts)

-- Search for the notes matching a given query.
map("n", "<leader>zf", "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>", opts)
-- Search for the notes matching the current visual selection.
map("v", "<leader>zf", ":'<,'>ZkMatch<CR>", opts)

-----------------------falsh-------------------------------------
map({ "n", "x", "o" }, "<leader>s", function()
	require("flash").jump()
end, dopts("Flash"))
map({ "n", "x", "o" }, "<leader>e", function()
	require("flash").treesitter()
end, dopts("Flash Treesitter"))
map({ "n", "x", "o" }, "<leader>re", function()
	require("flash").remote()
end, dopts("remote Flash"))
map({ "n", "x", "o" }, "<leader>v", function()
	require("flash").treesitter_search()
end, dopts("Treesitter Search"))

-----------------------llm ai-------------------------------------
map("n", "<leader>ag", "<cmd>lua _COMMIT_MSG()<cr>", dopts("avante generate commit msg"))

return pluginKeys
