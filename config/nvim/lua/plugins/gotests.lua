local M = {
  "crochee/gotests.nvim",
  ft = "go",
}

function M.config()
  require("gotests").setup({
    template = 'testify',
  })
end

return M
