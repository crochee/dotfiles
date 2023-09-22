local M = {
  'utilyre/barbecue.nvim',
  dependencies = {
    "neovim/nvim-lspconfig",
    "SmiteshP/nvim-navic"
  },
}

function M.config()
  local status, barbecue = pcall(require, "barbecue")
  if not status then
    vim.notify("没有找到 barbecue")
    return
  end

  barbecue.setup()
end

return M
