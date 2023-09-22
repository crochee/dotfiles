local M = {
  'edolphin-ydf/goimpl.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-lua/popup.nvim',
    'nvim-telescope/telescope.nvim',
    'nvim-treesitter/nvim-treesitter',
  },
  ft = 'go',
}

function M.config()
  require('telescope').load_extension('goimpl')
end

return M
