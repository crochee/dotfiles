local M = {
  'ur4ltz/surround.nvim'
}

function M.config()
  require("surround").setup({
    mapping_style = "surround",
  })
end

return M
