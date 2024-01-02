local M = {
  'nvim-lualine/lualine.nvim'
}
-- 底部状态栏
function M.config()
  local spaces = function()
    return "spaces: " .. vim.api.nvim_buf_get_option(0, "shiftwidth")
  end

  require('lualine').setup {
    options = {
      icons_enabled = true,
      theme = "auto",
      component_separators = { left = "", right = "" },
      section_separators = { left = "", right = "" },
      disabled_filetypes = { "alpha", "dashboard", "NvimTree", "Outline" },
      always_divide_middle = true,
    },
    sections = {
      lualine_c = {
        {
          'filename',
          file_status = true, -- displays file status (readonly status, modified status)
          path = 1            -- 0 = just filename, 1 = relative path, 2 = absolute path
        }
      },
      lualine_x = {
        spaces,
        "encoding",
        {
          "filetype",
          icons_enabled = true,
        },
      },
      lualine_y = {
        {
          "progress",
        },
      },
    },
  }
end

return M
