local M = {
  'nvim-tree/nvim-tree.lua',
  dependencies = { { 'nvim-tree/nvim-web-devicons' } },
}

function M.config()
  -- htps://github.com/kyazdani42/nvim-tree.lua
  -- local nvim_tree = require'nvim-tree'
  -- disable netrw at the very start of your init.lua
  vim.g.loaded_netrw = 1
  vim.g.loaded_netrwPlugin = 1

  -- set termguicolors to enable highlight groups
  vim.opt.termguicolors = true

  require('nvim-tree').setup({
    on_attach = require('configs.keymaps').nvimTree,
    -- 不显示 git 状态图标
    git = {
      enable = false,
    },
    -- project plugin 需要这样设置
    update_cwd = true,
    update_focused_file = {
      enable = true,
      update_cwd = true,
    },
    -- 隐藏不需要显示的文件
    filters = {
      dotfiles = true,
      custom = { 'node_modules', '.idea', '__pycache__' },
    },
    view = {
      -- 宽度
      width = 40,
      -- 也可以 'right'
      side = 'left',
      -- 不显示行数
      number = false,
      relativenumber = false,
      -- 显示图标
      signcolumn = 'yes',
    },
    actions = {
      open_file = {
        -- 首次打开大小适配
        resize_window = true,
        -- 打开文件时关闭 tree
        quit_on_open = true,
      },
    },
    -- wsl install -g wsl-open
    -- https://github.com/4U6U57/wsl-open/
    system_open = {
      cmd = 'open',
    },
  })
end

return M
