local M = {
  'folke/flash.nvim',
  event = 'VeryLazy',
}

function M.config()
  require('flash').setup({
    modes = {
      char = {
        enabled = false,
      }
    }
  })
end

return M
