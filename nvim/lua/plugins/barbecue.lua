local M = {
  'utilyre/barbecue.nvim',
  dependencies = {
    "neovim/nvim-lspconfig",
    "SmiteshP/nvim-navic"
  },
}

function M.config()
  require("barbecue").setup()
end

return M
