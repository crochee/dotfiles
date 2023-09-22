local M = {
  'kyazdani42/nvim-tree.lua'
}

function M.config()
  -- htps://github.com/kyazdani42/nvim-tree.lua
  -- local nvim_tree = require'nvim-tree'
  local status, nvim_tree = pcall(require, 'nvim-tree')
  if not status then
    vim.notify('没有找到 nvim-tree')
    return
  end

  nvim_tree.setup({
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
      -- 隐藏根目录
      hide_root_folder = false,
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
