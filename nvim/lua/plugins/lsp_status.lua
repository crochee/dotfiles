local M = {
  'nvim-lua/lsp-status.nvim'
}

function M.config()
  local lsp_status = require('lsp-status')
  lsp_status.register_progress()
  lsp_status.config({
    status_symbol = ' ',
  })
end

return M
