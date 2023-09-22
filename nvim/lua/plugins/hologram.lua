local M = {
  'edluffy/hologram.nvim',
}
-- 图片查看器
function M.config()
  require("hologram").setup({
    auto_display = true,
  })
end

return M
