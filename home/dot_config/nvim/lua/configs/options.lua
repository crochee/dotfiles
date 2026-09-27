-- history
vim.o.history = 2000

-- jkl 移动时光标周围保留 4 行
vim.o.scrolloff = 4
vim.o.sidescrolloff = 4

-- 行号
vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.signcolumn = "yes"
vim.o.colorcolumn = "120"

-- 缩进（4 空格代替 Tab）
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftround = true
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.autoindent = true
vim.o.smartindent = true

-- 搜索
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.incsearch = true

-- 命令行高度 2
vim.o.cmdheight = 2

-- 文件被外部程序修改时自动加载
vim.o.autoread = true

-- 折行关闭
vim.o.wrap = false

-- 光标在行首尾时 <Left>/<Right> 可跳到下一行
vim.o.whichwrap = "b,s,<,>,[,],h,l"

-- 鼠标
vim.o.mouse = "a"

-- 禁止创建备份 / 交换文件
vim.o.backup = false
vim.o.writebackup = false
vim.o.swapfile = false

-- 较小的 updatetime（影响 CursorHold 等）
vim.o.updatetime = 300

-- 键序列连击等待时间
vim.o.timeoutlen = 500

-- split 方向
vim.o.splitbelow = true
vim.o.splitright = true

-- 补全菜单行为
vim.o.completeopt = "menu,menuone,noselect,noinsert"

-- 命令行补全：wildmenu 默认画在全局状态栏，lualine 已接管状态栏会被遮挡，
-- 改用浮动菜单（pum）展示
vim.o.wildoptions = "pum"
vim.o.wildmode = "longest:full,full"

-- 配色 / 终端颜色
vim.o.background = "dark"
vim.o.termguicolors = true

-- 显示不可见字符
vim.o.list = true
vim.o.listchars = "space:·,tab:··,eol:↴"

-- 不在插入模式补全菜单显示 abort 消息
vim.o.shortmess = vim.o.shortmess .. "c"

-- 补全菜单最多显示行数
vim.o.pumheight = 10

-- 总是显示 tabline
vim.o.showtabline = 2

-- 由 lualine 接管模式提示
vim.o.showmode = false

-- 拼写
vim.o.spelllang = "en"
vim.o.spelloptions = "noplainbuffer"

-- 剪切板
vim.o.clipboard = "unnamedplus"
-- 会话恢复时保留文件类型和高亮等局部选项
vim.opt.sessionoptions:append("localoptions")
