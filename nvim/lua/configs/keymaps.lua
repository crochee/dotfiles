-- setting leader key to " "
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 本地变量
local map = vim.keymap.set

local opt = {
  noremap = true, --禁止递归
  silent = true   --执行命令时不回显内容
}

-- Modes
--   normal_mode = "n",
--   insert_mode = "i",
--   visual_mode = "v", --v
--   visual_block_mode = "x", -- C_v
--   term_mode = "t",
--   command_mode = "c",

-- save 插入模式下保存并退出到正常模式
map({ "i", "x", "n", "s" }, "<leader><Tab>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Clean search (highlight)取消高亮
map("n", "<leader><space>", ":noh<CR>", opt)

-- 上下左右(kjhl)
------------------------- visual模式下缩进代码-----------

map("v", "<", "<gv", opt)
map("v", ">", ">gv", opt)

-- 上下移动选中文本
map("v", "J", ":m '>+1<CR>gv=gv", opt)
map("v", "K", ":m '<-2<CR>gv=gv", opt)

----------------------- 分屏快捷键 ---------------------
-- sv 水平分屏sh 垂直分屏sc 关闭当前分屏 (s = close)so
map("n", "sv", ":vsp<CR>", opt) --水平分屏
map("n", "sh", ":sp<CR>", opt)  --垂直分屏
map("n", "sc", "<C-w>c", opt)   --关闭当前分屏 (s = close)
map("n", "so", "<C-w>o", opt)   --关闭其他分屏 (o = other)
-- alt + hjkl 在窗口之间跳转
map("n", "<A-h>", "<C-w>h", opt)
map("n", "<A-j>", "<C-w>j", opt)
map("n", "<A-k>", "<C-w>k", opt)
map("n", "<A-l>", "<C-w>l", opt)

--------------------------------------------------------------------

-- 插件快捷键
local pluginKeys = {}

-------------------------- nvimTree 目录树插件 ---------------------
map('n', '<leader>ll', ':NvimTreeToggle<CR>', opt)
-- 列表快捷键
pluginKeys.nvimTree = function(bufnr)
  local api = require('nvim-tree.api')

  local function opts(desc)
    return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end
  map('n', '<CR>', api.node.open.edit, opts('Open'))
  map('n', '<2-LeftMouse>', api.node.open.edit, opts('Open'))
  map('n', '<Tab>', api.node.open.preview, opts('Open Preview'))
  map('n', '.', api.tree.toggle_hidden_filter, opts('Toggle Dotfiles'))
  map('n', 'i', api.tree.toggle_gitignore_filter, opts('Toggle Git Ignore'))
  map('n', 'f', api.live_filter.start, opts('Filter'))
  map('n', 'F', api.live_filter.clear, opts('Clean Filter'))
  map('n', 'a', api.fs.create, opts('Create'))
  map('n', 'd', api.fs.remove, opts('Delete'))
  map('n', 'r', api.fs.rename, opts('Rename'))
  map('n', 'x', api.fs.cut, opts('Cut'))
  map('n', 'c', api.fs.copy.node, opts('Copy'))
  map('n', 'p', api.fs.paste, opts('Paste'))
  map('n', 'R', api.tree.reload, opts('Refresh'))
  map('n', 'A', api.tree.expand_all, opts('Expand All'))
  map('n', 'y', api.fs.copy.filename, opts('Copy Name'))
  map('n', 'yr', api.fs.copy.relative_path, opts('Copy Relative Path'))
  map('n', 'ya', api.fs.copy.absolute_path, opts('Copy Absolute Path'))
end

----------------------------------- bufferline --------------
-- Buffer nav
map("n", "<leader>q", ":BufferLineCyclePrev<CR>", opt)
map("n", "<leader>w", ":BufferLineCycleNext<CR>", opt)
-- Close buffer
map("n", "<leader>cc", ":bd<CR>", opt)
map("n", "<leader>cr", ":BufferLineCloseRight<CR>", opt)
map("n", "<leader>cl", ":BufferLineCloseLeft<CR>", opt)

------------------------------- Telescope  文件搜索 -------------------------
map("n", "<leader>ff", ":Telescope find_files<CR>", opt)
map("n", "<leader>fg", ":Telescope live_grep<CR>", opt)
map("n", "<leader>fs", ":Telescope lsp_document_symbols<CR>", opt)
map("n", "<leader>fb", ":Telescope buffers<CR>", opt)
map("n", "<leader>fh", ":Telescope help_tags<CR>", opt)
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
    -- ["<esc>"] = actions.close,
    ["<C-c>"] = "close",
    -- 预览窗口上下滚动
    ["<C-u>"] = "preview_scrolling_up",
    ["<C-d>"] = "preview_scrolling_down"
  }
}

---------------------- lsp 编程语言设置相关（代码跳转提示等）-------------------
-- lsp 回调函数快捷键设置
pluginKeys.maplsp = function(mapbuf)
  -- rename
  mapbuf('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opt)
  -- code action
  mapbuf('n', '<leader>a', '<cmd>lua vim.lsp.buf.code_action()<CR>', opt)
  -- go xx
  mapbuf('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opt)
  mapbuf('n', '<leader>gh', '<cmd>lua vim.lsp.buf.hover()<CR>', opt)
  mapbuf('n', '<leader>gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opt)
  mapbuf('n', '<leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opt)
  mapbuf('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>', opt)
  -- diagnostic
  mapbuf('n', '<leader>go', '<cmd>lua vim.diagnostic.open_float()<CR>', opt)
  mapbuf('n', '<leader>gp', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opt)
  mapbuf('n', '<leader>gn', '<cmd>lua vim.diagnostic.goto_next()<CR>', opt)
  mapbuf('n', '<leader>gq', '<cmd>lua vim.diagnostic.setloclist()<CR>', opt)

  mapbuf('n', '<leader>gf', '<cmd>lua vim.lsp.buf.format{ async = true }<CR>', opt)
  mapbuf('n', '<leader>gs', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opt)
  -- mapbuf('n', '<space>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opt)
  -- mapbuf('n', '<space>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opt)
  -- mapbuf('n', '<space>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opt)
  mapbuf('n', '<space>gtd', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opt)
end

-------------------- nvim-cmp 自动补全 --------------------------
pluginKeys.cmp = function(cmp)
  return {
    -- 上一个
    ['<leader>k'] = cmp.mapping.select_prev_item(),
    -- 下一个
    ['<leader>j'] = cmp.mapping.select_next_item(),
    -- 出现补全
    ['<A-.>'] = cmp.mapping(cmp.mapping.complete(), { 'i', 'c' }),
    -- 取消
    ['<A-,>'] = cmp.mapping({
      i = cmp.mapping.abort(),
      c = cmp.mapping.close(),
    }),
    -- 确认
    -- Accept currently selected item. If none selected, `select` first item.
    -- Set `select` to `false` to only confirm explicitly selected items.
    ['<CR>'] = cmp.mapping.confirm({
      select = true,
      behavior = cmp.ConfirmBehavior.Replace
    }),
    -- ['<C-y>'] = cmp.config.disable, -- Specify `cmp.config.disable` if you want to remove the default `<C-y>` mapping.
    ['<C-u>'] = cmp.mapping(cmp.mapping.scroll_docs(-4), { 'i', 'c' }),
    ['<C-d>'] = cmp.mapping(cmp.mapping.scroll_docs(4), { 'i', 'c' }),
  }
end

--------------------- floating terminal -----------------------------
-- toggleTerm & Lazygit
map('n', '<leader>tg', '<CMD>lua _LAZYGIT_TOGGLE()<CR>', opt)
map('n', '<leader>th', '<CMD>ToggleTerm direction=horizontal<CR>', opt)
map('n', '<leader>tv', '<CMD>ToggleTerm direction=vertical<CR>', opt)
map('n', '<leader>ta', '<CMD>ToggleTerm direction=tab<CR>', opt)
map('n', '<leader>tf', '<CMD>ToggleTerm direction=float<CR>', opt)
----------------------dap debug ------------------------------------
-- Begin
map("n", "<leader>dc", ":lua require('dap').continue()<CR>", opt)
map("n", "<leader>dd", ":RustDebuggables<CR>", opt)
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
  opt
)
-- Set BreakPoint
map("n", "<leader>dt", ":lua require('dap').toggle_breakpoint()<CR>", opt)
--  stepOver, stepOut, stepInto
map("n", "<leader>dn", ":lua require'dap'.step_over()<CR>", opt)
map("n", "<leader>do", ":lua require'dap'.step_out()<CR>", opt)
map("n", "<leader>di", ":lua require'dap'.step_into()<CR>", opt)
map("n", "<leader>dl", ":lua require'dap'.run_last()<CR>", opt)
-- Pop-ups
map("n", "<leader>dh", ":lua require'dapui'.eval()<CR>", opt)

-- golang debug test
map("n", "<leader>dgt", ":lua require('dap-go').debug_test()<CR>", opt)
map("n", "<leader>dgl", ":lua require('dap-go').debug_last_test()<CR>", opt)


--------------------gitsigns ----------------------------------
pluginKeys.mapgit = function(mapbuf)
  -- Navigation
  mapbuf('n', ']c', "&diff ? ']c' : '<cmd>Gitsigns next_hunk<CR>'", { expr = true })
  mapbuf('n', '[c', "&diff ? '[c' : '<cmd>Gitsigns prev_hunk<CR>'", { expr = true })

  -- Actions
  mapbuf('n', '<leader>hs', ':Gitsigns stage_hunk<CR>')
  mapbuf('v', '<leader>hs', ':Gitsigns stage_hunk<CR>')
  mapbuf('n', '<leader>hr', ':Gitsigns reset_hunk<CR>')
  mapbuf('v', '<leader>hr', ':Gitsigns reset_hunk<CR>')
  mapbuf('n', '<leader>hS', '<cmd>Gitsigns stage_buffer<CR>')
  mapbuf('n', '<leader>hu', '<cmd>Gitsigns undo_stage_hunk<CR>')
  mapbuf('n', '<leader>hR', '<cmd>Gitsigns reset_buffer<CR>')
  mapbuf('n', '<leader>hp', '<cmd>Gitsigns preview_hunk<CR>')
  mapbuf('n', '<leader>hb', '<cmd>lua require"gitsigns".blame_line{full=true}<CR>')
  mapbuf('n', '<leader>tb', '<cmd>Gitsigns toggle_current_line_blame<CR>')
  mapbuf('n', '<leader>hd', '<cmd>Gitsigns diffthis<CR>')
  mapbuf('n', '<leader>hD', '<cmd>lua require"gitsigns".diffthis("~")<CR>')
  mapbuf('n', '<leader>td', '<cmd>gitsigns toggle_deleted<cr>')

  -- Text object
  mapbuf('o', 'ih', ':<C-U>Gitsigns select_hunk<CR>')
  mapbuf('x', 'ih', ':<C-U>Gitsigns select_hunk<CR>')
end

------------------------gotests golang单元测试自动生成-----------------------
map("n", "<leader>ge", ":GoTests<CR>", opt)
map("n", "<leader>gta", ":GoTestsAll<CR>", opt)
map("n", "<leader>gte", ":GoTestsExported<CR>", opt)

----------------------git-conflict------------------------
map('n', '<leader>co', '<Plug>(git-conflict-ours)')
map('n', '<leader>ct', '<Plug>(git-conflict-theirs)')
map('n', '<leader>cb', '<Plug>(git-conflict-both)')
map('n', '<leader>c0', '<Plug>(git-conflict-none)')
map('n', '<leader>cp', '<Plug>(git-conflict-prev-conflict)')
map('n', '<leader>cn', '<Plug>(git-conflict-next-conflict)')

-- --------------------markdown-preview-----------------------
map('n', '<leader>mp', ':MarkdownPreview<CR>', opt)
map('n', '<leader>ms', ':MarkdownPreviewStop<CR>', opt)
map('n', '<leader>mt', ':MarkdownPreviewToggle<CR>', opt)

-----------------------goimpl---------------------------------
map('n', '<leader>im', '<Plug>(go-impl>')

-----------------------open file with browser-------------------
function _SHOW_BROWSER_FILE_PATH()
  local filePath = ''
  if vim.fn.has("wsl") == 1 then
    filePath = "file://wsl.localhost/Ubuntu-22.04" .. vim.fn.expand('%:p')
  else
    filePath = "file:/" .. vim.fn.expand('%:p')
  end
  vim.notify(filePath)
  -- 将内容复制到寄存器
  vim.fn.setreg('+', filePath)
end

vim.api.nvim_create_user_command('ShowBrowserFilePath', _SHOW_BROWSER_FILE_PATH, {})

----------------------zk-------------------------------------
-- Create a new note after asking for its title.
map("n", "<leader>zn", "<Cmd>ZkNew { title = vim.fn.input('Title: ') }<CR>", opt)

-- Open notes.
map("n", "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", opt)
-- Open notes associated with the selected tags.
map("n", "<leader>zt", "<Cmd>ZkTags<CR>", opt)

-- Search for the notes matching a given query.
map("n", "<leader>zf",
  "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>", opt)
-- Search for the notes matching the current visual selection.
map("v", "<leader>zf", ":'<,'>ZkMatch<CR>", opt)

----------------------marks-------------------------------------
map("n", "<leader>ma", "<Cmd>MarksListAll<CR>", opt)

return pluginKeys
