local M = {
  "chentoast/marks.nvim",
  event = "BufEnter",
}

function M.config()
  require("marks").setup({
    default_mappings = false,
  })
end

return M
