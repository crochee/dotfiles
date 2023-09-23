local M = {
  "chentoast/marks.nvim",
  event = "BufEnter",
}

function M.config()
  require("marks").setup({})
end

return M
