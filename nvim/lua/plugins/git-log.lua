local M = {
  'niuiic/git-log.nvim',
  dependencies = {
    'niuiic/core.nvim'
  }
}
function M.config()
  require("git-log").setup()
end

return M
