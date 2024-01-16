local M = {
  -- 'ellisonleao/gruvbox.nvim',
  'sainnhe/everforest',
  -- 'navarasu/onedark.nvim',
  -- "folke/tokyonight.nvim",
}

function M.config()
  -- 主题配置（皮肤）

  -- 皮肤设置
  vim.cmd [[
  if has('termguicolors')
    set termguicolors
  endif

  set background=dark
  " set background=light
  ]]

  -- require("colorschemes.gruvbox")
  require("colorschemes.everforest")
  -- require("colorschemes.onedark")
  -- require("colorschemes.tokyonight")
end

return M
